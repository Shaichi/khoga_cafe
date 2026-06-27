package com.khoga.scheduler;

import com.khoga.order.OrderService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-88: READY orders idle beyond {@code READY_ABANDON_TIMEOUT} (default 15 min) become ABANDONED with
 * no stock refund (stock was deducted at PREPARING, BR-07). Runs every minute via {@link OrderService#abandonStaleReadyOrders}.
 */
@Slf4j
@Component
public class OrderTimeoutScheduler {

    private final OrderService orderService;

    public OrderTimeoutScheduler(OrderService orderService) {
        this.orderService = orderService;
    }

    @Scheduled(cron = "0 * * * * *")
    public void abandonStaleReadyOrders() {
        int abandoned = orderService.abandonStaleReadyOrders();
        if (abandoned > 0) {
            log.info("[scheduler] OrderTimeout abandoned {} stale READY order(s)", abandoned);
        }
    }
}
