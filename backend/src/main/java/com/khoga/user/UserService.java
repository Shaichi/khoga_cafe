package com.khoga.user;

import com.khoga.audit.AuditJson;
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
        requireUniqueContact(request.email(), request.phone(), null);
        long sequence = nextEmployeeSequence();
        String employeeId = String.format("EMP-%03d", sequence);
        String username = allocateUsername(request.fullName(), sequence);
        String temporaryPassword = "12345678";

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
            throw AppException.of("err.081");   // BR-82
        }
        requireUniqueContact(request.email(), request.phone(), id);
        String oldJson = userSnapshot(user);        // BR-81 before-image
        if (StringUtils.hasText(request.fullName())) {
            user.setFullName(request.fullName());
        }
        if (request.role() != null) {
            user.setRole(request.role());
        }
        user.setStore(resolveStore(request.storeId()));
        user.setPhone(StringUtils.hasText(request.phone()) ? request.phone() : null);
        if (StringUtils.hasText(request.email())) {
            user.setEmail(request.email());
        }
        userRepository.save(user);
        auditLogService.record(ActionType.UPDATE, "User", oldJson, userSnapshot(user), actorId);
        return UserMapper.toResponse(user);
    }

    /** UC-14: toggle active. BR-82 blocks self-deactivation; BR-23 protects the last active SSADMIN. */
    @Transactional
    public UserResponse setActive(UUID id, boolean active, UUID actorId) {
        User user = load(id);
        if (!active && id.equals(actorId)) {
            throw AppException.of("err.082");      // BR-82
        }
        if (!active && user.getRole() == Role.SSADMIN && Boolean.TRUE.equals(user.getIsActive())
                && userRepository.countByRoleAndIsActiveTrue(Role.SSADMIN) <= 1) {
            throw AppException.of("err.083"); // BR-23
        }
        boolean wasActive = Boolean.TRUE.equals(user.getIsActive());
        user.setIsActive(active);
        if (!active) {
            // BR-18: revoke any tokens already in flight. JwtAuthenticationFilter rejects an
            // inactive user, and bumping tokenVersion invalidates the issued tokens explicitly.
            user.setTokenVersion((user.getTokenVersion() != null ? user.getTokenVersion() : 0) + 1);
        }
        userRepository.save(user);
        // BR-81: capture before/after active flag; a deactivation carries the semantic DEACTIVATE action.
        String oldJson = AuditJson.snapshot().put("id", id.toString()).put("active", wasActive).json();
        String newJson = AuditJson.snapshot().put("id", id.toString()).put("active", active).json();
        auditLogService.record(active ? ActionType.UPDATE : ActionType.DEACTIVATE,
                "User", oldJson, newJson, actorId);
        return UserMapper.toResponse(user);
    }

    /**
     * Email and phone must be unique across accounts. {@code excludeId} skips the row being updated so a
     * user keeping their own contact details is not flagged against themselves.
     */
    private void requireUniqueContact(String email, String phone, UUID excludeId) {
        if (StringUtils.hasText(email)) {
            boolean taken = excludeId == null
                    ? userRepository.existsByEmail(email)
                    : userRepository.existsByEmailAndIdNot(email, excludeId);
            if (taken) {
                throw AppException.of("err.090");
            }
        }
        if (StringUtils.hasText(phone)) {
            boolean taken = excludeId == null
                    ? userRepository.existsByPhone(phone)
                    : userRepository.existsByPhoneAndIdNot(phone, excludeId);
            if (taken) {
                throw AppException.of("err.091");
            }
        }
    }

    /**
     * BR-57: the next free employee number. Seeds the candidate from the row count then skips any
     * {@code EMP-xxx} already taken, so a retired/deleted number is never re-issued as a duplicate
     * (the old {@code count()+1} silently collided once any account had been removed).
     */
    private long nextEmployeeSequence() {
        long candidate = userRepository.count() + 1;
        while (userRepository.existsByEmployeeId(String.format("EMP-%03d", candidate))) {
            candidate++;
        }
        return candidate;
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

    /** BR-81 before/after image of the mutable account fields. */
    private String userSnapshot(User user) {
        return AuditJson.snapshot()
                .put("fullName", user.getFullName())
                .put("role", user.getRole() == null ? null : user.getRole().name())
                .put("storeId", user.getStore() == null ? null : user.getStore().getId().toString())
                .put("email", user.getEmail())
                .put("phone", user.getPhone())
                .json();
    }

    private User load(UUID id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }
}
