package com.khoga;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

/**
 * Full-context smoke test. Tagged {@code integration} because it needs the SQL Server database and
 * runs the {@code DataSeeder}; CI excludes this tag and runs only the pure unit tests
 * ({@code -DexcludedGroups=integration}). Run it locally with {@code ./mvnw verify}.
 */
@Tag("integration")
@SpringBootTest
class CoffeeshopApplicationTests {

    @Test
    void contextLoads() {
    }

}
