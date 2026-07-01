package com.khoga.config;

import com.khoga.auth.JwtAuthenticationFilter;
import com.khoga.common.dto.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import java.io.IOException;
import java.util.Locale;

/**
 * Stateless, JWT-based security. The anonymous auth flows (login/forgot/verify/reset) + API docs +
 * welcome page are public; everything else (including logout, change-password, force-password-change
 * and the profile endpoints) requires a valid token. Authentication (401) and authorization (403)
 * failures are rendered as an
 * {@link ApiResponse}-shaped JSON envelope so clients get a consistent error format. Role-based
 * authorization is enforced per-endpoint via {@code @PreAuthorize} ({@link EnableMethodSecurity}).
 */
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final MessageSource messageSource;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter, MessageSource messageSource) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.messageSource = messageSource;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(
                                "/",
                                "/v3/api-docs/**",
                                "/swagger-ui/**",
                                "/swagger-ui.html",
                                // Health/info probes for load balancers + Docker healthcheck.
                                "/actuator/health",
                                "/actuator/health/**",
                                "/actuator/info"
                        ).permitAll()
                        // Only the truly anonymous auth flows are public. Authenticated auth
                        // operations (logout, change-password, force-password-change) and the
                        // profile endpoints fall through to authenticated() below.
                        .requestMatchers(HttpMethod.POST,
                                "/api/v1/auth/login",
                                "/api/v1/auth/login/mfa",
                                "/api/v1/auth/forgot-password",
                                "/api/v1/auth/verify-otp",
                                "/api/v1/auth/reset-password",
                                // VietQR gateway webhook — authenticated by HMAC signature, not JWT (BR-84)
                                "/api/v1/payments/vietqr/callback"
                        ).permitAll()
                        .anyRequest().authenticated()
                )
                .exceptionHandling(eh -> eh
                        // These run in the filter chain (before @ControllerAdvice), so localize here
                        // directly from the request's Accept-Language. 401 = MSG04, 403 = MSG08.
                        .authenticationEntryPoint((request, response, ex) ->
                                writeError(response, HttpServletResponse.SC_UNAUTHORIZED, msg(request, "MSG04")))
                        .accessDeniedHandler((request, response, ex) ->
                                writeError(response, HttpServletResponse.SC_FORBIDDEN, msg(request, "MSG08"))))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /**
     * Resolve a message code for an unauthenticated request. Vietnamese is the default; English is
     * used only when {@code Accept-Language} explicitly asks for it. (We read the header directly
     * rather than {@code LocaleContextHolder}, which Spring MVC has not populated this early.)
     */
    private String msg(HttpServletRequest request, String code) {
        String acceptLanguage = request.getHeader("Accept-Language");
        Locale locale = acceptLanguage != null && acceptLanguage.toLowerCase().startsWith("en")
                ? Locale.ENGLISH : Locale.forLanguageTag("vi");
        return messageSource.getMessage(code, null, code, locale);
    }

    /**
     * Writes an {@link ApiResponse}-shaped error body by hand. We intentionally avoid an injected
     * ObjectMapper: Spring Boot 4 ships Jackson 3 ({@code tools.jackson}), while the only
     * {@code com.fasterxml.jackson} mapper on the classpath comes transitively from jjwt — so there
     * is no autowirable mapper bean of that type. The payload is tiny and the message is escaped.
     */
    private void writeError(HttpServletResponse response, int status, String message) throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"status\":\"error\",\"message\":\"" + escapeJson(message) + "\",\"data\":null}");
    }

    private static String escapeJson(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
