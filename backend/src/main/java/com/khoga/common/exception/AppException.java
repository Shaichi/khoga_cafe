package com.khoga.common.exception;

/**
 * Business-rule failure → HTTP 400 (via {@code GlobalExceptionHandler}).
 *
 * <p>Two flavours:
 * <ul>
 *   <li>{@link #AppException(String)} — a ready-to-show literal message (the legacy form, still used
 *       widely). {@link #getCode()} is {@code null} and the handler emits the literal verbatim.</li>
 *   <li>{@link #of(String, Object...)} — an i18n message <em>code</em> (e.g. {@code "MSG16"}) plus
 *       MessageFormat args; the handler resolves it against the request locale. This is preferred for
 *       new code so messages are localizable.</li>
 * </ul>
 */
public class AppException extends RuntimeException {

    private final String code;
    private final transient Object[] args;

    /** Legacy form: {@code message} is shown as-is; no i18n code. */
    public AppException(String message) {
        super(message);
        this.code = null;
        this.args = new Object[0];
    }

    private AppException(String code, Object[] args, boolean coded) {
        super(code);   // fallback rendering = the code itself if no bundle entry exists
        this.code = code;
        this.args = args != null ? args : new Object[0];
    }

    /** i18n form: resolve {@code code} (with {@code args}) via MessageSource in the handler. */
    public static AppException of(String code, Object... args) {
        return new AppException(code, args, true);
    }

    /** Non-null only for the {@link #of} form. */
    public String getCode() {
        return code;
    }

    public Object[] getArgs() {
        return args;
    }
}
