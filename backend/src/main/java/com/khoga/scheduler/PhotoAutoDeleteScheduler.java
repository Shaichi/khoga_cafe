package com.khoga.scheduler;

import com.khoga.staff.AttendanceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-72 (PDPA): null out attendance photos older than the retention window (default 90 days), keeping
 * the log row. Runs daily at 02:00 via {@link AttendanceService#purgeExpiredPhotos}.
 */
@Slf4j
@Component
public class PhotoAutoDeleteScheduler {

    private final AttendanceService attendanceService;

    public PhotoAutoDeleteScheduler(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    @Scheduled(cron = "0 0 2 * * *")
    public void purgeExpiredPhotos() {
        int purged = attendanceService.purgeExpiredPhotos();
        if (purged > 0) {
            log.info("[scheduler] PhotoAutoDelete purged {} expired attendance photo(s)", purged);
        }
    }
}
