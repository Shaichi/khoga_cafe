package com.khoga.customer;

import com.khoga.common.model.Customer;
import com.khoga.common.model.Order;
import com.khoga.customer.dto.CustomerOrderEntry;
import com.khoga.customer.dto.CustomerResponse;

/** Hand-written entity→DTO mapper (project convention: no MapStruct). */
final class CustomerMapper {

    private CustomerMapper() {
    }

    static CustomerResponse toResponse(Customer c) {
        return new CustomerResponse(c.getId(), c.getPhone(), c.getFullName(), c.getEmail(),
                c.getPoints(), c.getConsentAt(), c.getConsentVersion());
    }

    static CustomerOrderEntry toOrderEntry(Order o) {
        return new CustomerOrderEntry(o.getId(), o.getOrderNumber(), o.getTotal(), o.getStatus(), o.getCreatedAt());
    }
}
