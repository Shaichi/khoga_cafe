package com.khoga.auth;

import com.khoga.common.exception.AppException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

/**
 * Reads the authenticated user id that {@link JwtAuthenticationFilter} stored as the security
 * principal. Endpoints behind authentication can rely on this; it throws if there is no principal.
 */
public final class SecurityUtil {

    private SecurityUtil() {
    }

    public static UUID currentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UUID userId)) {
            throw new AppException("Yêu cầu xác thực");
        }
        return userId;
    }
}
