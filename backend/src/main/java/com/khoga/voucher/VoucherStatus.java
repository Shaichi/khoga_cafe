package com.khoga.voucher;

/**
 * Derived (non-persisted) lifecycle status of a voucher (BR-52). Three states per the RDS §3.4.3
 * statechart: SCHEDULED (before validFrom), ACTIVE (in-window & is_active), EXPIRED (past validTo or
 * deactivated — terminal). Usage exhaustion does NOT change status; it only blocks further redemption.
 */
public enum VoucherStatus {
    SCHEDULED, ACTIVE, EXPIRED
}
