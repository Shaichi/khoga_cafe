package com.khoga.common.model.enums;

public enum Role {
    // Branch-scoped roles
    CASHIER, BARISTA, STORE_MANAGER,
    // HQ roles (chain-wide). CEOVIEWER = read-only consolidated chain reports (SRS §2.1, BR-44);
    // BUSINESSADMIN owns master data / promotions / loyalty adjustments (BR-49, UC-74);
    // SSADMIN is the system super-admin (seeded bootstrap account, BR-82).
    CEOVIEWER, BUSINESSADMIN, SSADMIN
}
