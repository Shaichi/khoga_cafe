package com.khoga.auth;

import com.khoga.auth.dto.ProfileResponse;
import com.khoga.auth.dto.ProfileUpdateRequest;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.User;
import com.khoga.common.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.UUID;

/**
 * Self-service profile read/update (UC-07/UC-08). Only contact fields (email, phone) are editable;
 * role, username and branch are not touched here (BR-19).
 */
@Service
public class ProfileService {

    private final UserRepository userRepository;

    public ProfileService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfile(UUID userId) {
        return toResponse(load(userId));
    }

    @Transactional
    public ProfileResponse updateProfile(UUID userId, ProfileUpdateRequest request) {
        User user = load(userId);
        // Treat only non-blank values as edits, so an omitted/empty field never blanks existing data.
        if (StringUtils.hasText(request.email())) {
            user.setEmail(request.email());
        }
        if (StringUtils.hasText(request.phone())) {
            user.setPhone(request.phone());
        }
        userRepository.save(user);
        return toResponse(user);
    }

    private User load(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }

    private ProfileResponse toResponse(User u) {
        UUID storeId = u.getStore() != null ? u.getStore().getId() : null;
        String storeName = u.getStore() != null ? u.getStore().getName() : null;
        return new ProfileResponse(u.getId(), u.getUsername(), u.getFullName(),
                u.getEmail(), u.getPhone(), u.getRole(), storeId, storeName);
    }
}
