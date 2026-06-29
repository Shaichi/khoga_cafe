package com.khoga.auth;

import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * BR-18 unit tests for the JWT auth filter's server-side invalidation. A real {@link JwtTokenProvider}
 * mints tokens; the {@link UserRepository} is mocked to represent current server state. The filter is
 * exercised directly (no Spring context) and the resulting {@link SecurityContextHolder} state is
 * asserted.
 */
class JwtAuthenticationFilterTest {

    private static final String SECRET = "khoga-test-secret-please-change-0123456789abcdef";

    private final JwtTokenProvider provider = new JwtTokenProvider(SECRET, 120, 480);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final JwtAuthenticationFilter filter = new JwtAuthenticationFilter(provider, userRepository);

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    private User user(UUID id, boolean active, Integer tokenVersion) {
        User u = new User();
        u.setId(id);
        u.setRole(Role.CASHIER);
        u.setIsActive(active);
        u.setTokenVersion(tokenVersion);
        return u;
    }

    private HttpServletRequest bearer(String token) {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        return request;
    }

    private void run(HttpServletRequest request) throws Exception {
        FilterChain chain = mock(FilterChain.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        filter.doFilterInternal(request, response, chain);
        verify(chain).doFilter(request, response);   // the chain always proceeds
    }

    @Test
    void validToken_activeUser_matchingVersion_authenticates() throws Exception {
        UUID id = UUID.randomUUID();
        String token = provider.generateToken(id, Role.CASHIER, null, 2);
        when(userRepository.findById(id)).thenReturn(Optional.of(user(id, true, 2)));

        run(bearer(token));

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assertEquals(id, auth.getPrincipal());
        assertTrue(auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CASHIER")));
    }

    @Test
    void deactivatedUser_isNotAuthenticated() throws Exception {
        UUID id = UUID.randomUUID();
        String token = provider.generateToken(id, Role.CASHIER, null, 2);
        when(userRepository.findById(id)).thenReturn(Optional.of(user(id, false, 2)));

        run(bearer(token));

        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test
    void staleTokenVersion_isNotAuthenticated() throws Exception {
        UUID id = UUID.randomUUID();
        String token = provider.generateToken(id, Role.CASHIER, null, 1);   // old version
        when(userRepository.findById(id)).thenReturn(Optional.of(user(id, true, 2)));   // bumped since

        run(bearer(token));

        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test
    void unknownUser_isNotAuthenticated() throws Exception {
        UUID id = UUID.randomUUID();
        String token = provider.generateToken(id, Role.CASHIER, null, 0);
        when(userRepository.findById(id)).thenReturn(Optional.empty());

        run(bearer(token));

        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test
    void legacyUserWithNullVersion_acceptsVersionZeroToken() throws Exception {
        UUID id = UUID.randomUUID();
        String token = provider.generateToken(id, Role.CASHIER, null, 0);
        when(userRepository.findById(id)).thenReturn(Optional.of(user(id, true, null)));   // legacy row

        run(bearer(token));

        assertEquals(id, SecurityContextHolder.getContext().getAuthentication().getPrincipal());
    }

    @Test
    void noToken_passesThroughWithoutDbLookup() throws Exception {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getHeader("Authorization")).thenReturn(null);
        when(request.getCookies()).thenReturn(null);

        run(request);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(userRepository, never()).findById(org.mockito.ArgumentMatchers.any());
    }
}
