package com.khoga.auth;

import com.khoga.common.model.enums.Role;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * P0.1 unit tests for JWT generation/parsing. No Spring context — pure logic.
 * (HTTP-level 401/403 behaviour is verified in P0.8 once real endpoints exist.)
 */
class JwtTokenProviderTest {

    private static final String SECRET = "khoga-test-secret-please-change-0123456789abcdef";
    private final JwtTokenProvider provider = new JwtTokenProvider(SECRET, 120, 480);

    @Test
    void generateAndParse_roundTripsClaims() {
        UUID userId = UUID.randomUUID();
        UUID storeId = UUID.randomUUID();

        String token = provider.generateToken(userId, Role.CASHIER, storeId, 0);

        assertTrue(provider.isValid(token));
        Claims claims = provider.parse(token);
        assertEquals(userId, provider.getUserId(claims));
        assertEquals(Role.CASHIER, provider.getRole(claims));
        assertEquals(storeId, provider.getStoreId(claims));
    }

    @Test
    void storeId_isOptional_forHqRoles() {
        String token = provider.generateToken(UUID.randomUUID(), Role.SSADMIN, null, 0);
        assertNull(provider.getStoreId(provider.parse(token)));
    }

    @Test
    void hqRole_getsShorterTtlThanBranchRole() {
        UUID id = UUID.randomUUID();
        Claims hq = provider.parse(provider.generateToken(id, Role.SSADMIN, null, 0));      // 120 min
        Claims branch = provider.parse(provider.generateToken(id, Role.CASHIER, null, 0));  // 480 min

        long hqTtl = hq.getExpiration().getTime() - hq.getIssuedAt().getTime();
        long branchTtl = branch.getExpiration().getTime() - branch.getIssuedAt().getTime();
        assertTrue(hqTtl < branchTtl, "HQ token must expire sooner than a branch token");
    }

    @Test
    void tokenVersion_roundTrips() {                                       // BR-18
        Claims claims = provider.parse(provider.generateToken(UUID.randomUUID(), Role.CASHIER, null, 7));
        assertEquals(7, provider.getTokenVersion(claims));
    }

    @Test
    void invalidToken_isRejected() {
        assertFalse(provider.isValid("not-a-jwt"));
    }

    @Test
    void tokenSignedWithDifferentSecret_isRejected() {
        String foreign = new JwtTokenProvider("a-totally-different-secret-0123456789abcdef", 120, 480)
                .generateToken(UUID.randomUUID(), Role.CASHIER, null, 0);
        assertFalse(provider.isValid(foreign), "token signed with a different key must not validate");
    }
}
