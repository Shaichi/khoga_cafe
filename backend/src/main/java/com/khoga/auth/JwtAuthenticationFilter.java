package com.khoga.auth;

import com.khoga.common.model.User;
import com.khoga.common.repository.UserRepository;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

/**
 * Reads the {@code Authorization: Bearer <jwt>} header (or the {@code khoga_token} cookie) on each
 * request and, when the token is accepted, populates the {@link SecurityContextHolder} with an
 * authentication whose principal is the user id and whose authority is {@code ROLE_<role>}.
 *
 * <p><b>BR-18 — server-side invalidation.</b> Beyond signature+expiry, a present token is checked
 * against current server state: the user must still exist, be {@code isActive}, and the token's
 * {@code tv} claim must match the user's {@code tokenVersion}. A password change (which bumps
 * {@code tokenVersion}) or a deactivation therefore revokes every previously-issued token on the
 * next request. This costs one DB read per authenticated request — the deliberate trade-off for
 * stateless soft-invalidation without a token blacklist / Redis. Requests with no token skip the
 * lookup entirely.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider tokenProvider;
    private final UserRepository userRepository;

    public JwtAuthenticationFilter(JwtTokenProvider tokenProvider, UserRepository userRepository) {
        this.tokenProvider = tokenProvider;
        this.userRepository = userRepository;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        String token = resolveToken(request);
        if (token != null && tokenProvider.isValid(token)
                && SecurityContextHolder.getContext().getAuthentication() == null) {
            Claims claims = tokenProvider.parse(token);
            UUID userId = tokenProvider.getUserId(claims);
            if (isStillValid(userId, tokenProvider.getTokenVersion(claims))) {
                var authority = new SimpleGrantedAuthority("ROLE_" + tokenProvider.getRole(claims).name());
                var authentication = new UsernamePasswordAuthenticationToken(
                        userId, null, List.of(authority));
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
            // Otherwise leave the context unauthenticated so SecurityConfig's entry point returns 401.
        }
        filterChain.doFilter(request, response);
    }

    /** BR-18: the user must still exist, be active, and the token's version must be current. */
    private boolean isStillValid(UUID userId, int tokenVersion) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null || Boolean.FALSE.equals(user.getIsActive())) {
            return false;
        }
        int current = user.getTokenVersion() != null ? user.getTokenVersion() : 0;
        return tokenVersion == current;
    }

    private String resolveToken(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (StringUtils.hasText(header) && header.startsWith(BEARER_PREFIX)) {
            return header.substring(BEARER_PREFIX.length());
        }
        if (request.getCookies() != null) {
            for (jakarta.servlet.http.Cookie cookie : request.getCookies()) {
                if ("khoga_token".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }
}
