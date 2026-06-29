package com.khoga.auth;

import com.khoga.common.model.enums.Role;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Set;
import java.util.UUID;

/**
 * Issues and verifies stateless JWTs carrying {@code userId} (subject), {@code role} and
 * {@code storeId}. Token lifetime follows the NFR: HQ roles get a shorter TTL than branch roles.
 */
@Component
public class JwtTokenProvider {

    /** HQ roles get the shorter TTL (BR-83 / NFR §4.2). */
    private static final Set<Role> HQ_ROLES = Set.of(Role.SSADMIN, Role.BUSINESSADMIN);

    private final SecretKey key;
    private final long hqExpirationMillis;
    private final long branchExpirationMillis;

    public JwtTokenProvider(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.expiration-hq-minutes}") long hqMinutes,
            @Value("${app.jwt.expiration-branch-minutes}") long branchMinutes) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.hqExpirationMillis = hqMinutes * 60_000L;
        this.branchExpirationMillis = branchMinutes * 60_000L;
    }

    public String generateToken(UUID userId, Role role, UUID storeId, int tokenVersion) {
        Instant now = Instant.now();
        long ttl = HQ_ROLES.contains(role) ? hqExpirationMillis : branchExpirationMillis;
        return Jwts.builder()
                .subject(userId.toString())
                .claim("role", role.name())
                .claim("storeId", storeId != null ? storeId.toString() : null)
                .claim("tv", tokenVersion)                     // BR-18 invalidation anchor
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(ttl)))
                .signWith(key)
                .compact();
    }

    public Claims parse(String token) {
        return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
    }

    public boolean isValid(String token) {
        try {
            parse(token);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    public UUID getUserId(Claims claims) {
        return UUID.fromString(claims.getSubject());
    }

    public Role getRole(Claims claims) {
        return Role.valueOf(claims.get("role", String.class));
    }

    public UUID getStoreId(Claims claims) {
        String storeId = claims.get("storeId", String.class);
        return storeId != null ? UUID.fromString(storeId) : null;
    }

    /** BR-18: the token's invalidation version. Legacy tokens without the claim read as {@code 0}. */
    public int getTokenVersion(Claims claims) {
        Integer v = claims.get("tv", Integer.class);
        return v != null ? v : 0;
    }
}
