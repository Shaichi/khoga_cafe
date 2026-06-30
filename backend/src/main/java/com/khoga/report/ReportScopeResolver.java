package com.khoga.report;

import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.UserRepository;
import org.springframework.stereotype.Component;

import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/**
 * BR-44 reporting scope: HQ roles (ceoviewer/businessadmin/ssadmin) see the whole chain and may
 * filter to any branch (or all); a Store Manager is locked to their own branch and may not query
 * another. Centralised here so every report endpoint enforces the same rule.
 */
@Component
public class ReportScopeResolver {

    private static final Set<Role> HQ_ROLES = EnumSet.of(Role.CEOVIEWER, Role.BUSINESSADMIN, Role.SSADMIN);

    private final UserRepository userRepository;

    public ReportScopeResolver(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User requireUser(UUID actorId) {
        return userRepository.findById(actorId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }

    public boolean isHq(Role role) {
        return HQ_ROLES.contains(role);
    }

    /**
     * Resolves the branch a report query may target.
     *
     * @return the effective store id, or {@code null} meaning "all branches" (HQ, no filter)
     * @throws AppException if a Store Manager tries to read another branch (BR-44)
     */
    public UUID resolveBranch(UUID actorId, UUID requestedBranchId) {
        User actor = requireUser(actorId);
        if (isHq(actor.getRole())) {
            return requestedBranchId; // null = chain-wide
        }
        // Store Manager (or any branch role) — locked to own branch.
        if (actor.getStore() == null) {
            throw AppException.of("err.057");
        }
        UUID own = actor.getStore().getId();
        if (requestedBranchId != null && !requestedBranchId.equals(own)) {
            throw AppException.of("err.058");
        }
        return own;
    }

    /** A branch report that must always be branch-scoped (e.g. Store Manager's own-branch Z-report). */
    public UUID requireOwnBranch(UUID actorId) {
        User actor = requireUser(actorId);
        if (actor.getStore() == null) {
            throw AppException.of("err.059");
        }
        return actor.getStore().getId();
    }
}
