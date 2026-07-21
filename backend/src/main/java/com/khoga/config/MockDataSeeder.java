package com.khoga.config;

import com.khoga.common.model.*;
import com.khoga.common.model.enums.*;
import com.khoga.common.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Slf4j
@Component
@Profile("!prod")
@RequiredArgsConstructor
public class MockDataSeeder implements CommandLineRunner {

    private final CategoryRepository categoryRepository;
    private final MenuItemRepository menuItemRepository;
    private final CustomerRepository customerRepository;
    private final VoucherRepository voucherRepository;

    @Override
    @Transactional
    public void run(String... args) {
        if (categoryRepository.count() == 0) {
            Category drink = new Category();
            drink.setName("Cà phê");
            drink.setIsActive(true);
            drink = categoryRepository.save(drink);

            MenuItem item1 = new MenuItem();
            item1.setName("Cà phê đen đá");
            item1.setCategory(drink);
            item1.setPrice(new BigDecimal("29000"));
            item1.setIsActive(true);
            menuItemRepository.save(item1);

            MenuItem item2 = new MenuItem();
            item2.setName("Cà phê sữa đá");
            item2.setCategory(drink);
            item2.setPrice(new BigDecimal("35000"));
            item2.setIsActive(true);
            menuItemRepository.save(item2);
            
            Category tea = new Category();
            tea.setName("Trà trái cây");
            tea.setIsActive(true);
            tea = categoryRepository.save(tea);

            MenuItem item3 = new MenuItem();
            item3.setName("Trà đào cam sả");
            item3.setCategory(tea);
            item3.setPrice(new BigDecimal("45000"));
            item3.setIsActive(true);
            menuItemRepository.save(item3);
            
            log.info("[seed] Seeded mock menu items.");
        }

        if (customerRepository.count() == 0) {
            Customer c = new Customer();
            c.setFullName("Nguyễn Văn A");
            c.setPhone("0901234567");
            c.setPoints(15000);
            c.setIsActive(true);
            customerRepository.save(c);
            log.info("[seed] Seeded mock customer.");
        }

        if (voucherRepository.count() == 0) {
            Voucher v = new Voucher();
            v.setCode("GIAM10K");
            v.setDescription("Giảm 10K cho đơn từ 50K");
            v.setDiscountType(DiscountType.FIXED_AMOUNT);
            v.setDiscountValue(new BigDecimal("10000"));
            v.setMinOrderValue(new BigDecimal("50000"));
            v.setStartDate(LocalDateTime.now().minusDays(1));
            v.setEndDate(LocalDateTime.now().plusMonths(12));
            v.setIsActive(true);
            voucherRepository.save(v);
            log.info("[seed] Seeded mock voucher.");
        }
    }
}
