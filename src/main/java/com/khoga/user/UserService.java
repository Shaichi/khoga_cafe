package com.khoga.user;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.integration.EmailService;
import com.khoga.user.dto.CreateUserRequest;
import com.khoga.user.dto.UpdateUserRequest;
import com.khoga.user.dto.UserDetailResponse;
import com.khoga.user.dto.UserResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.UUID;

/**
 * Employee account administration (UC-10/11/12/13/14), HQ-only. Creation auto-allocates an employee
 * id (BR-57) + username (BR-58) + temporary password (BR-22) and emails the welcome credentials;
 * every mutation is audited (BR-81). Self-escalation (BR-82) and last-admin removal (BR-23) are blocked.
 */
@Service
public class UserService {

    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final AuditLogRepository auditLogRepository;
    private final AuditLogService auditLogService;
    private final EmailService emailService;
    private final UsernameGenerator usernameGenerator;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, StoreRepository storeRepository,
                       AuditLogRepository auditLogRepository, AuditLogService auditLogService,
                       EmailService emailService, UsernameGenerator usernameGenerator,
                       PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.storeRepository = storeRepository;
        this.auditLogRepository = auditLogRepository;
        this.auditLogService = auditLogService;
        this.emailService = emailService;
        this.usernameGenerator = usernameGenerator;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public Page<UserResponse> list(Role role, String search, Pageable pageable) {
        Page<User> page;
        if (StringUtils.hasText(search)) {
            page = userRepository.findByUsernameContainingIgnoreCaseOrFullNameContainingIgnoreCase(
                    search, search, pageable);
        } else if (role != null) {
            page = userRepository.findByRole(role, pageable);
        } else {
            page = userRepository.findAll(pageable);
        }
        return page.map(UserMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public UserDetailResponse get(UUID id) {
        User user = load(id);
        return UserMapper.toDetail(user, auditLogRepository.findTop50ByUserIdOrderByCreatedAtDesc(id));
    }

    @Transactional
    public UserResponse create(CreateUserRequest request, UUID actorId) {
        long sequence = userRepository.count() + 1;
        String employeeId = String.format("EMP-%03d", sequence);
        String username = allocateUsername(request.fullName(), sequence);
        String temporaryPassword = TemporaryPasswordGenerator.generate();

        User user = new User();
        user.setEmployeeId(employeeId);
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(temporaryPassword));
        user.setRole(request.role());
        user.setFullName(request.fullName());
        user.setEmail(request.email());
        user.setPhone(request.phone());
        user.setIsActive(true);
        user.setMustChangePassword(true);     // BR-22
        user.setFailedAttempts(0);
        user.setStore(resolveStore(request.storeId()));
        User saved = userRepository.save(user);

        emailService.send(request.email(), "Tài khoản Khoga của bạn",
                "Tên đăng nhập: " + username + " — Mật khẩu tạm: " + temporaryPassword
                        + ". Vui lòng đổi mật khẩu trong lần đăng nhập đầu tiên.");
        auditLogService.record(ActionType.CREATE, "User", null,
                "{\"username\":\"" + username + "\",\"role\":\"" + request.role() + "\"}", actorId);
        return UserMapper.toResponse(saved);
    }

    @Transactional
    public UserResponse update(UUID id, UpdateUserRequest request, UUID actorId) {
        User user = load(id);
        if (id.equals(actorId) && request.role() != null && request.role() != user.getRole()) {
            throw new AppException("Không thể tự thay đổi vai trò của chính mình");   // BR-82
        }
        if (request.role() != null) {
            user.setRole(request.role());
        }
        if (request.storeId() != null) {
            user.setStore(resolveStore(request.storeId()));
        }
        if (StringUtils.hasText(request.email())) {
            user.setEmail(request.email());
        }
        if (StringUtils.hasText(request.phone())) {
            user.setPhone(request.phone());
        }
        userRepository.save(user);
        auditLogService.record(ActionType.UPDATE, "User", null, "{\"id\":\"" + id + "\"}", actorId);
        return UserMapper.toResponse(user);
    }

    /** UC-14: toggle active. BR-82 blocks self-deactivation; BR-23 protects the last active SSADMIN. */
    @Transactional
    public UserResponse setActive(UUID id, boolean active, UUID actorId) {
        User user = load(id);
        if (!active && id.equals(actorId)) {
            throw new AppException("Không thể tự vô hiệu hóa tài khoản của mình");      // BR-82
        }
        if (!active && user.getRole() == Role.SSADMIN && Boolean.TRUE.equals(user.getIsActive())
                && userRepository.countByRoleAndIsActiveTrue(Role.SSADMIN) <= 1) {
            throw new AppException("Không thể vô hiệu hóa tài khoản SSADMIN hoạt động cuối cùng"); // BR-23
        }
        user.setIsActive(active);
        userRepository.save(user);
        // BR-18 (revoke active tokens on deactivate) is deferred to P4 — tokens are stateless today.
        auditLogService.record(ActionType.UPDATE, "User", null,
                "{\"id\":\"" + id + "\",\"active\":" + active + "}", actorId);
        return UserMapper.toResponse(user);
    }

    private String allocateUsername(String fullName, long sequence) {
        String base = usernameGenerator.generate(fullName, sequence);
        String candidate = base;
        int suffix = 1;
        while (userRepository.existsByUsername(candidate)) {
            candidate = base + "-" + suffix++;
        }
        return candidate;
    }

    private Store resolveStore(UUID storeId) {
        if (storeId == null) {
            return null;
        }
        return storeRepository.findById(storeId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh"));
    }

    private User load(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }
}
