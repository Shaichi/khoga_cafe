package com.khoga.scheduler;

import com.khoga.common.model.ShiftSession;
import com.khoga.pos.ShiftService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-88 / BR-92: auto-close shift sessions left OPEN past end of day, at 23:59 daily. Each shift is
 * closed via {@link ShiftService#autoClose}, which force-abandons READY orders first and skips any
 * shift that still has non-terminal work (BR-03).
 */
@Slf4j
@Component
public class ShiftAutoCloseScheduler {

    private final ShiftService shiftService;

    public ShiftAutoCloseScheduler(ShiftService shiftService) {
        this.shiftService = shiftService;
    }

    @Scheduled(cron = "0 59 23 * * *")
    public void autoCloseOpenShifts() {
        for (ShiftSession session : shiftService.openShifts()) {
            shiftService.autoClose(session.getId());
        }
    }
}
