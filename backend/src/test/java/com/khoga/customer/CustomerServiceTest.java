package com.khoga.customer;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.customer.dto.CreateCustomerRequest;
import com.khoga.customer.dto.PointAdjustmentRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.5 unit tests: enrolment consent + unique phone (BR-71), point adjustment guard (BR-49). */
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CustomerService service;

    @Test
    void create_duplicatePhone_throws() {
        when(customerRepository.existsByPhone("0900000001")).thenReturn(true);
        CreateCustomerRequest request = new CreateCustomerRequest("0900000001", "An", "an@x.com", "v1");

        assertThrows(AppException.class, () -> service.create(request, UUID.randomUUID()));
        verify(customerRepository, never()).save(any());
    }

    @Test
    void create_stampsConsentAndZeroPoints() {
        when(customerRepository.existsByPhone("0900000001")).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(inv -> inv.getArgument(0));

        service.create(new CreateCustomerRequest("0900000001", "An", "an@x.com", "v1"), UUID.randomUUID());

        ArgumentCaptor<Customer> captor = ArgumentCaptor.forClass(Customer.class);
        verify(customerRepository).save(captor.capture());
        Customer saved = captor.getValue();
        assertEquals(0, saved.getPoints());
        assertEquals("v1", saved.getConsentVersion());
        assertNotNull(saved.getConsentAt());                 // BR-71
    }

    @Test
    void adjustPoints_drivingNegative_throws() {
        UUID id = UUID.randomUUID();
        Customer c = new Customer();
        c.setId(id);
        c.setPoints(10);
        when(customerRepository.findById(id)).thenReturn(Optional.of(c));

        assertThrows(AppException.class, () ->
                service.adjustPoints(id, new PointAdjustmentRequest(-20, "correction"), UUID.randomUUID()));
        verify(customerRepository, never()).save(any());
    }

    @Test
    void adjustPoints_valid_updatesAndAudits() {
        UUID id = UUID.randomUUID();
        UUID actor = UUID.randomUUID();
        Customer c = new Customer();
        c.setId(id);
        c.setPoints(10);
        when(customerRepository.findById(id)).thenReturn(Optional.of(c));

        service.adjustPoints(id, new PointAdjustmentRequest(15, "goodwill bonus"), actor);

        assertEquals(25, c.getPoints());
        verify(customerRepository).save(c);
        verify(auditLogService).record(eq(ActionType.UPDATE), eq("Customer"), any(), any(), eq(actor));
    }
}
