package com.khoga.staff;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.StaffSchedule;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftType;
import com.khoga.common.repository.StaffScheduleRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.integration.EmailService;
import com.khoga.staff.dto.CreateScheduleRequest;
import com.khoga.staff.dto.ScheduleResponse;
import com.khoga.staff.dto.UpdateScheduleRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.4 unit tests for scheduling rules: A46 cashier register, BR-92 hours/conflict, BR-36 past-guard, BR-37 notify. */
@ExtendWith(MockitoExtension.class)
class ScheduleServiceTest {

    @Mock private StaffScheduleRepository scheduleRepository;
    @Mock private UserRepository userRepository;
    @Mock private SystemConfigService config;
    @Mock private AuditLogService auditLogService;
    @Mock private EmailService emailService;
    @InjectMocks private ScheduleService service;

    private final UUID actorId = UUID.randomUUID();
    private final UUID storeId = UUID.randomUUID();
    private final UUID employeeId = UUID.randomUUID();

    private Store store() {
        Store s = new Store();
        s.setId(storeId);
        s.setName("Branch 1");
        return s;
    }

    private User manager() {
        User u = new User();
        u.setId(actorId);
        u.setStore(store());
        return u;
    }

    private User employee(Role role) {
        User u = new User();
        u.setId(employeeId);
        u.setFullName("Anna");
        u.setUsername("anna");
        u.setRole(role);
        u.setIsActive(true);
        u.setStore(store());
        return u;
    }

    private StaffSchedule shift(LocalDate date, LocalTime start, LocalTime end) {
        StaffSchedule s = new StaffSchedule();
        s.setId(UUID.randomUUID());
        s.setStore(store());
        s.setUser(employee(Role.BARISTA));
        s.setShiftDate(date);
        s.setShiftStartTime(start);
        s.setShiftEndTime(end);
        return s;
    }

    private void stubEmptyConstraints() {
        when(config.getGlobalInt(anyString(), anyInt())).thenAnswer(inv -> inv.getArgument(1));
        when(scheduleRepository.findByUserIdAndShiftDate(eq(employeeId), any())).thenReturn(List.of());
        when(scheduleRepository.findByUserIdAndShiftDateBetween(eq(employeeId), any(), any())).thenReturn(List.of());
        when(scheduleRepository.findByStoreIdAndShiftDate(eq(storeId), any())).thenReturn(List.of());
    }

    @Test
    void create_happyPath() {
        LocalDate date = LocalDate.now().plusDays(1);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(userRepository.findById(employeeId)).thenReturn(Optional.of(employee(Role.BARISTA)));
        stubEmptyConstraints();
        when(scheduleRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CreateScheduleRequest req = new CreateScheduleRequest(employeeId, date, ShiftType.MORNING,
                LocalTime.of(8, 0), LocalTime.of(12, 0), null, null);
        ScheduleResponse res = service.create(req, actorId);

        assertNotNull(res);
        verify(scheduleRepository).save(any());
    }

    @Test
    void create_crossBranch_writesDedicatedAuditRow_BR90() {
        LocalDate date = LocalDate.now().plusDays(1);
        UUID homeStoreId = UUID.randomUUID();
        User emp = employee(Role.BARISTA);
        Store home = new Store();
        home.setId(homeStoreId);
        emp.setStore(home); // employee's home branch differs from the target (manager's) branch
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(userRepository.findById(employeeId)).thenReturn(Optional.of(emp));
        stubEmptyConstraints();
        when(scheduleRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CreateScheduleRequest req = new CreateScheduleRequest(employeeId, date, ShiftType.MORNING,
                LocalTime.of(8, 0), LocalTime.of(12, 0), null, null);
        service.create(req, actorId);

        // BR-90: a dedicated cross-branch audit row carrying home + target store, not just a flag.
        verify(auditLogService).record(any(), eq("StaffScheduleCrossBranch"), any(),
                argThat(json -> json.contains(homeStoreId.toString()) && json.contains(storeId.toString())),
                eq(actorId));
    }

    @Test
    void create_cashierWithoutRegister_throws_A46() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(userRepository.findById(employeeId)).thenReturn(Optional.of(employee(Role.CASHIER)));

        CreateScheduleRequest req = new CreateScheduleRequest(employeeId, LocalDate.now().plusDays(1),
                ShiftType.MORNING, LocalTime.of(8, 0), LocalTime.of(12, 0), null, null);

        assertThrows(AppException.class, () -> service.create(req, actorId));
        verify(scheduleRepository, never()).save(any());
    }

    @Test
    void create_dailyHoursExceeded_throws_BR92() {
        LocalDate date = LocalDate.now().plusDays(1);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(userRepository.findById(employeeId)).thenReturn(Optional.of(employee(Role.BARISTA)));
        when(config.getGlobalInt(anyString(), anyInt())).thenAnswer(inv -> inv.getArgument(1)); // defaults (daily 12h)
        when(scheduleRepository.findByUserIdAndShiftDate(eq(employeeId), any()))
                .thenReturn(List.of(shift(date, LocalTime.of(6, 0), LocalTime.of(16, 0)))); // 10h already

        CreateScheduleRequest req = new CreateScheduleRequest(employeeId, date, ShiftType.AFTERNOON,
                LocalTime.of(16, 0), LocalTime.of(20, 0), null, null); // +4h → 14h > 12h

        assertThrows(AppException.class, () -> service.create(req, actorId));
        verify(scheduleRepository, never()).save(any());
    }

    @Test
    void create_overlappingShift_throws_BR92() {
        LocalDate date = LocalDate.now().plusDays(1);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(userRepository.findById(employeeId)).thenReturn(Optional.of(employee(Role.BARISTA)));
        when(config.getGlobalInt(anyString(), anyInt())).thenAnswer(inv -> inv.getArgument(1));
        when(scheduleRepository.findByUserIdAndShiftDate(eq(employeeId), any())).thenReturn(List.of());
        when(scheduleRepository.findByUserIdAndShiftDateBetween(eq(employeeId), any(), any()))
                .thenReturn(List.of(shift(date, LocalTime.of(11, 0), LocalTime.of(15, 0))));

        CreateScheduleRequest req = new CreateScheduleRequest(employeeId, date, ShiftType.MORNING,
                LocalTime.of(9, 0), LocalTime.of(12, 0), null, null); // overlaps 11:00–15:00

        assertThrows(AppException.class, () -> service.create(req, actorId));
        verify(scheduleRepository, never()).save(any());
    }

    @Test
    void update_pastSchedule_throws_BR36() {
        UUID id = UUID.randomUUID();
        StaffSchedule past = shift(LocalDate.now().minusDays(2), LocalTime.of(8, 0), LocalTime.of(12, 0));
        past.setId(id);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(scheduleRepository.findById(id)).thenReturn(Optional.of(past));

        UpdateScheduleRequest req = new UpdateScheduleRequest(ShiftType.MORNING,
                LocalTime.of(8, 0), LocalTime.of(13, 0), null, null);

        assertThrows(AppException.class, () -> service.update(id, req, actorId));
        verify(scheduleRepository, never()).save(any());
    }

    @Test
    void delete_notifiesEmployee_BR37() {
        UUID id = UUID.randomUUID();
        StaffSchedule sched = shift(LocalDate.now().plusDays(1), LocalTime.of(8, 0), LocalTime.of(12, 0));
        sched.setId(id);
        sched.getUser().setEmail("anna@khoga.test");
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager()));
        when(scheduleRepository.findById(id)).thenReturn(Optional.of(sched));

        service.delete(id, actorId);

        verify(scheduleRepository).delete(sched);
        verify(emailService).send(eq("anna@khoga.test"), any(), any());
    }
}
