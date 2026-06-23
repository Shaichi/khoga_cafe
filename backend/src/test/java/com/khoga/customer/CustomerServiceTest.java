package com.khoga.customer;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.Order;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.customer.dto.CreateCustomerRequest;
import com.khoga.customer.dto.CustomerOrderEntry;
import com.khoga.customer.dto.CustomerResponse;
import com.khoga.customer.dto.PointAdjustmentRequest;
import com.khoga.customer.dto.UpdateCustomerRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
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

/**
 * P1.5 unit tests: enrolment consent + unique phone (BR-71), point adjustment guard (BR-49),
 * partial-update semantics (UC-26), and read paths (list/get/history, UC-24/27).
 */
@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CustomerService service;

    @Test
    void create_duplicatePhone_throws() {
        when(customerRepository.existsByPhone("0900000001")).thenReturn(true);
        CreateCustomerRequest request = new CreateCustomerRequest("0900000001", "An", "an@x.com", null, "v1");

        assertThrows(AppException.class, () -> service.create(request, UUID.randomUUID()));
        verify(customerRepository, never()).save(any());
    }

    @Test
    void create_stampsConsentAndZeroPoints_withBirthDateAndIsActive() {
        when(customerRepository.existsByPhone("0900000001")).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(inv -> inv.getArgument(0));

        java.time.LocalDate birthDate = java.time.LocalDate.of(1995, 5, 15);
        service.create(new CreateCustomerRequest("0900000001", "An", "an@x.com", birthDate, "v1"), UUID.randomUUID());

        ArgumentCaptor<Customer> captor = ArgumentCaptor.forClass(Customer.class);
        verify(customerRepository).save(captor.capture());
        Customer saved = captor.getValue();
        assertEquals(0, saved.getPoints());
        assertEquals("v1", saved.getConsentVersion());
        assertNotNull(saved.getConsentAt());                 // BR-71
        assertEquals(birthDate, saved.getBirthDate());       // Spec gap: birthDate
        assertEquals(true, saved.getIsActive());             // Spec gap: isActive
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

    @Test
    void update_changesProvidedFields_andAudits() {
        UUID id = UUID.randomUUID();
        UUID actor = UUID.randomUUID();
        Customer c = new Customer();
        c.setId(id);
        c.setFullName("Old Name");
        c.setEmail("old@x.com");
        when(customerRepository.findById(id)).thenReturn(Optional.of(c));
        when(customerRepository.save(any(Customer.class))).thenAnswer(inv -> inv.getArgument(0));

        LocalDate birthDate = LocalDate.of(1990, 1, 2);
        CustomerResponse res = service.update(id,
                new UpdateCustomerRequest("New Name", "new@x.com", birthDate), actor);

        assertEquals("New Name", c.getFullName());
        assertEquals("new@x.com", c.getEmail());
        assertEquals(birthDate, c.getBirthDate());
        assertEquals("New Name", res.fullName());
        verify(customerRepository).save(c);
        verify(auditLogService).record(eq(ActionType.UPDATE), eq("Customer"), any(), any(), eq(actor));
    }

    @Test
    void update_ignoresNullAndBlankFields() {
        UUID id = UUID.randomUUID();
        Customer c = new Customer();
        c.setId(id);
        c.setFullName("Keep Name");
        c.setEmail("keep@x.com");
        c.setBirthDate(LocalDate.of(1988, 3, 4));
        when(customerRepository.findById(id)).thenReturn(Optional.of(c));
        when(customerRepository.save(any(Customer.class))).thenAnswer(inv -> inv.getArgument(0));

        // blank name + null email + null birthDate → all left untouched
        service.update(id, new UpdateCustomerRequest("   ", null, null), UUID.randomUUID());

        assertEquals("Keep Name", c.getFullName());
        assertEquals("keep@x.com", c.getEmail());
        assertEquals(LocalDate.of(1988, 3, 4), c.getBirthDate());
    }

    @Test
    void get_notFound_throws() {
        UUID id = UUID.randomUUID();
        when(customerRepository.findById(id)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.get(id));
    }

    @Test
    void history_returnsMappedOrders() {
        UUID id = UUID.randomUUID();
        Customer c = new Customer();
        c.setId(id);
        when(customerRepository.findById(id)).thenReturn(Optional.of(c));

        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-001");
        order.setTotal(new BigDecimal("50000"));
        order.setStatus(OrderStatus.COMPLETED);
        when(orderRepository.findTop50ByCustomerIdOrderByCreatedAtDesc(id)).thenReturn(List.of(order));

        List<CustomerOrderEntry> history = service.history(id);

        assertEquals(1, history.size());
        assertEquals("ORD-001", history.get(0).orderNumber());
        assertEquals(0, new BigDecimal("50000").compareTo(history.get(0).total()));
        assertEquals(OrderStatus.COMPLETED, history.get(0).status());
    }

    @Test
    void history_customerNotFound_throws() {
        UUID id = UUID.randomUUID();
        when(customerRepository.findById(id)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.history(id));
        verify(orderRepository, never()).findTop50ByCustomerIdOrderByCreatedAtDesc(any());
    }

    @Test
    void list_withSearch_usesSearchQuery() {
        Pageable pageable = PageRequest.of(0, 20);
        Customer c = new Customer();
        c.setId(UUID.randomUUID());
        c.setPhone("0900000001");
        when(customerRepository.findByPhoneContainingOrFullNameContainingIgnoreCase("an", "an", pageable))
                .thenReturn(new PageImpl<>(List.of(c)));

        Page<CustomerResponse> page = service.list("an", pageable);

        assertEquals(1, page.getTotalElements());
        verify(customerRepository).findByPhoneContainingOrFullNameContainingIgnoreCase("an", "an", pageable);
        verify(customerRepository, never()).findAll(any(Pageable.class));
    }

    @Test
    void list_withoutSearch_usesFindAll() {
        Pageable pageable = PageRequest.of(0, 20);
        when(customerRepository.findAll(pageable)).thenReturn(new PageImpl<>(List.of()));

        service.list(null, pageable);

        verify(customerRepository).findAll(pageable);
        verify(customerRepository, never())
                .findByPhoneContainingOrFullNameContainingIgnoreCase(any(), any(), any());
    }
}
