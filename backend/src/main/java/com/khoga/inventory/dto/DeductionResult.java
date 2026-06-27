package com.khoga.inventory.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/** Result of a UC-62 recipe deduction: ingredients whose stock went negative (phantom usage, BR-89). */
public record DeductionResult(List<Shortage> shortages) {

    public record Shortage(UUID stockItemId, String materialName, BigDecimal deficit) {
    }

    public boolean hasShortage() {
        return shortages != null && !shortages.isEmpty();
    }
}
