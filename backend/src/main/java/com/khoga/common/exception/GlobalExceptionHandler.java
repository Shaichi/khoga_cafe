package com.khoga.common.exception;

import com.khoga.common.dto.ApiResponse;
import com.khoga.common.i18n.Messages;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.LinkedHashMap;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler {

    private final Messages messages;

    public GlobalExceptionHandler(Messages messages) {
        this.messages = messages;
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResponse.error(resolve(ex)));
    }

    @ExceptionHandler(AppException.class)
    public ResponseEntity<ApiResponse<Void>> handleAppException(AppException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResponse.error(resolve(ex)));
    }

    /**
     * Bean Validation failures on {@code @Valid} request bodies — aggregate field errors into
     * the {@code data} map so the client can highlight each invalid field. Per-field text comes
     * from the constraint (localized via ValidationMessages_*.properties); only the envelope
     * message is resolved here.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(error -> fieldErrors.putIfAbsent(error.getField(), error.getDefaultMessage()));
        ApiResponse<Map<String, String>> body = ApiResponse.<Map<String, String>>builder()
                .status("error")
                .message(messages.get("error.validation"))
                .data(fieldErrors)
                .build();
        return ResponseEntity.badRequest().body(body);
    }

    /**
     * Authorization failures raised after authentication — both {@code @PreAuthorize} denials and
     * explicit data-scope checks (e.g. a store manager touching another branch) — map to HTTP 403.
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResponse<Void>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResponse.error(messages.get("MSG08")));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleGenericException(Exception ex) {
        // Do not leak the raw exception detail to the client; log/observe it elsewhere.
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResponse.error(messages.get("error.unexpected")));
    }

    /** Coded exceptions ({@link AppException#of}) are localized; legacy literal messages pass through. */
    private String resolve(AppException ex) {
        return ex.getCode() != null ? messages.get(ex.getCode(), ex.getArgs()) : ex.getMessage();
    }
}
