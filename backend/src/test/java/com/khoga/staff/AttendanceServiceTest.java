package com.khoga.staff;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.AttendanceLog;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.AttendanceStatus;
import com.khoga.common.repository.AttendanceLogRepository;
import com.khoga.common.repository.StaffScheduleRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.staff.dto.AttendanceMetrics;
import com.khoga.staff.dto.AttendanceResponse;
import com.khoga.staff.dto.CheckInRequest;
import com.khoga.staff.dto.CheckOutRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.4 unit tests for attendance: PIN identify + lock (BR-93), photo fallback, check-out pairing, BR-72 purge. */
@ExtendWith(MockitoExtension.class)
class AttendanceServiceTest {

    @Mock private AttendanceLogRepository attendanceLogRepository;
    @Mock private StaffScheduleRepository scheduleRepository;
    @Mock private UserRepository userRepository;
    @Mock private SystemConfigService config;
    @Mock private AttendanceMetricsCalculator metricsCalculator;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private AttendanceService service;

    private final UUID actorId = UUID.randomUUID();
    private final UUID storeId = UUID.randomUUID();
    private final UUID employeeId = UUID.randomUUID();

    private Store store() {
        Store s = new Store();
        s.setId(storeId);
        return s;
    }

    private User operator() {
        User u = new User();
        u.setId(actorId);
        u.setStore(store());
        return u;
    }

    private User employee(String pin) {
        User u = new User();
        u.setId(employeeId);
        u.setFullName("Anna");
        u.setUsername("anna");
        u.setIsActive(true);
        u.setAttendancePin(pin);
        u.setStore(store());
        return u;
    }

    private void stubPresentMetrics() {
        when(config.getGlobalInt(eq("ATTENDANCE_LATE_GRACE_MINUTES"), eq(5))).thenReturn(5);
        when(metricsCalculator.derive(any(), any(), any(), any(), anyLong()))
                .thenReturn(new AttendanceMetrics(AttendanceStatus.PRESENT, 0, 0, 0, 0));
    }

    @Test
    void checkIn_withPhoto_recorded() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(employee("1234")));
        when(attendanceLogRepository.existsByUserIdAndShiftDateAndCheckOutAtIsNull(eq(employeeId), any()))
                .thenReturn(false);
        when(scheduleRepository.findByUserIdAndShiftDate(eq(employeeId), any())).thenReturn(List.of());
        stubPresentMetrics();
        when(attendanceLogRepository.save(any())).thenAnswer(inv -> {
            AttendanceLog l = inv.getArgument(0);
            l.setId(UUID.randomUUID());
            return l;
        });

        AttendanceResponse res = service.checkIn(new CheckInRequest("1234", "https://photo/1.jpg"), actorId);

        assertEquals(AttendanceStatus.PRESENT, res.status());
        assertTrue(res.photoCaptured());
        assertFalse(res.pendingVerification());
    }

    @Test
    void checkIn_noPhoto_pendingVerification_BR93() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(employee("1234")));
        when(attendanceLogRepository.existsByUserIdAndShiftDateAndCheckOutAtIsNull(eq(employeeId), any()))
                .thenReturn(false);
        when(scheduleRepository.findByUserIdAndShiftDate(eq(employeeId), any())).thenReturn(List.of());
        stubPresentMetrics();
        when(attendanceLogRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        AttendanceResponse res = service.checkIn(new CheckInRequest("1234", null), actorId);

        assertTrue(res.pendingVerification());
        assertFalse(res.photoCaptured());
    }

    @Test
    void checkIn_invalidPin_throws() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(employee("9999")));

        assertThrows(AppException.class, () -> service.checkIn(new CheckInRequest("0000", "p"), actorId));
        verify(attendanceLogRepository, never()).save(any());
    }

    @Test
    void checkIn_lockedPin_throws_BR93() {
        User locked = employee("1234");
        locked.setPinLockedUntil(LocalDateTime.now().plusMinutes(10));
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(locked));

        assertThrows(AppException.class, () -> service.checkIn(new CheckInRequest("1234", "p"), actorId));
        verify(attendanceLogRepository, never()).save(any());
    }

    @Test
    void checkOut_updatesOpenPairing() {
        AttendanceLog open = new AttendanceLog();
        open.setId(UUID.randomUUID());
        open.setUser(employee("1234"));
        open.setStore(store());
        open.setShiftDate(LocalDate.now());
        open.setCheckInAt(LocalDateTime.now().minusHours(4));
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(employee("1234")));
        when(attendanceLogRepository.findFirstByUserIdAndShiftDateAndCheckOutAtIsNull(eq(employeeId), any()))
                .thenReturn(Optional.of(open));
        when(attendanceLogRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        AttendanceResponse res = service.checkOut(new CheckOutRequest("1234"), actorId);

        assertNotNull(res.checkOutAt());
    }

    @Test
    void checkOut_noOpenLog_throws() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(operator()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(employee("1234")));
        when(attendanceLogRepository.findFirstByUserIdAndShiftDateAndCheckOutAtIsNull(eq(employeeId), any()))
                .thenReturn(Optional.empty());

        assertThrows(AppException.class, () -> service.checkOut(new CheckOutRequest("1234"), actorId));
        verify(attendanceLogRepository, never()).save(any());
    }

    @Test
    void purgeExpiredPhotos_nullsPhotoUrl_BR72() {
        AttendanceLog old = new AttendanceLog();
        old.setId(UUID.randomUUID());
        old.setPhotoUrl("https://photo/old.jpg");
        when(config.getGlobalInt(eq("PHOTO_RETENTION_DAYS"), eq(90))).thenReturn(90);
        when(attendanceLogRepository.findByPhotoUrlIsNotNullAndCheckInAtBefore(any(LocalDateTime.class)))
                .thenReturn(List.of(old));
        when(attendanceLogRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        int count = service.purgeExpiredPhotos();

        assertEquals(1, count);
        assertEquals(null, old.getPhotoUrl());
    }
}
