package com.khoga.common.model.enums;

public enum ActionType {
    CREATE,
    UPDATE,
    DELETE,
    /** Selling-price change on a menu item / topping (BR-68, UC-19). */
    PRICE_UPDATE,
    /** Manual loyalty-point adjustment on a customer (BR-49, UC-26). */
    POINT_ADJUSTMENT,
    /** Change to a system configuration value (UC-24, §3.11). */
    CONFIG_UPDATE,
    /** Deactivation of an account / branch / voucher (soft-off), distinct from a generic UPDATE. */
    DEACTIVATE
}
