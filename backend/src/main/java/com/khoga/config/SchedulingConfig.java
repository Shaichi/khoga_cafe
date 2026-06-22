package com.khoga.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Enables {@code @Scheduled} support for the timer skeletons in {@code com.khoga.scheduler}.
 * The timers log no-ops today; their real logic is filled in per the owning subsystem's phase.
 */
@Configuration
@EnableScheduling
public class SchedulingConfig {
}
