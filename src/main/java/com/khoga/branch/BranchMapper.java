package com.khoga.branch;

import com.khoga.branch.dto.BranchResponse;
import com.khoga.common.model.Store;

/** Hand-written entity→DTO mapper (project convention: no MapStruct). */
final class BranchMapper {

    private BranchMapper() {
    }

    static BranchResponse toResponse(Store store) {
        return new BranchResponse(
                store.getId(),
                store.getName(),
                store.getAddress(),
                store.getPhone(),
                Boolean.TRUE.equals(store.getIsActive()),
                store.getCreatedAt(),
                store.getUpdatedAt());
    }
}
