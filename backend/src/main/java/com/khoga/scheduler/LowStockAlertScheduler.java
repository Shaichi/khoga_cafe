package com.khoga.scheduler;

import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.integration.EmailService;
import com.khoga.inventory.StockService;
import com.khoga.inventory.dto.LowStockAlertDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * BR-04 / MSG07: nightly low-stock sweep at 22:00. For each active branch with items at/below their
 * alert threshold (or negative, BR-89), emails the branch's active Store Manager(s). Read-only over
 * stock — it raises alerts but performs no mutation.
 */
@Slf4j
@Component
public class LowStockAlertScheduler {

    private final StockService stockService;
    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public LowStockAlertScheduler(StockService stockService, StoreRepository storeRepository,
                                  UserRepository userRepository, EmailService emailService) {
        this.stockService = stockService;
        this.storeRepository = storeRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    @Scheduled(cron = "0 0 22 * * *")
    public void alertLowStock() {
        for (Store store : storeRepository.findAll()) {
            if (!Boolean.TRUE.equals(store.getIsActive())) {
                continue;
            }
            List<LowStockAlertDto> low = stockService.checkLowStock(store.getId());
            if (low.isEmpty()) {
                continue;
            }
            String body = buildBody(store, low);
            for (User manager : branchManagers(store.getId())) {
                emailService.send(manager.getEmail(), "[MSG07] Cảnh báo tồn kho thấp — " + store.getName(), body);
            }
            log.info("[scheduler] LowStockAlert: {} item(s) below threshold at store {}", low.size(), store.getName());
        }
    }

    private List<User> branchManagers(java.util.UUID storeId) {
        return userRepository.findByStoreId(storeId).stream()
                .filter(u -> u.getRole() == Role.STORE_MANAGER)
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> u.getEmail() != null && !u.getEmail().isBlank())
                .toList();
    }

    private String buildBody(Store store, List<LowStockAlertDto> low) {
        StringBuilder sb = new StringBuilder("Chi nhánh ").append(store.getName())
                .append(" có ").append(low.size()).append(" nguyên liệu dưới ngưỡng cảnh báo:\n");
        for (LowStockAlertDto i : low) {
            sb.append("- ").append(i.name()).append(" (").append(i.code()).append("): còn ")
                    .append(i.currentQuantity()).append(", ngưỡng ").append(i.minAlertThreshold()).append('\n');
        }
        return sb.toString();
    }
}
