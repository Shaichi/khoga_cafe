package com.khoga.audit;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Tiny hand-rolled JSON writer for audit before/after snapshots (BR-80/68/81). Kept deliberately
 * dependency-free — Spring Boot 4 ships Jackson 3 and there is no autowirable classic ObjectMapper
 * (see CLAUDE.md) — and scoped to flat maps of {@code String / Number / Boolean / null}, which is all
 * an audit snapshot needs. Values are escaped so free-text fields (names, reasons) can't break the JSON.
 */
public final class AuditJson {

    private AuditJson() {
    }

    /** Start a small ordered field set: {@code AuditJson.snapshot().put("k", v).json()}. */
    public static Snapshot snapshot() {
        return new Snapshot();
    }

    public static final class Snapshot {
        private final Map<String, Object> fields = new LinkedHashMap<>();

        public Snapshot put(String key, Object value) {
            fields.put(key, value);
            return this;
        }

        public String json() {
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<String, Object> e : fields.entrySet()) {
                if (!first) {
                    sb.append(',');
                }
                first = false;
                sb.append('"').append(escape(e.getKey())).append("\":").append(value(e.getValue()));
            }
            return sb.append('}').toString();
        }

        private static String value(Object v) {
            if (v == null) {
                return "null";
            }
            if (v instanceof Number || v instanceof Boolean) {
                return v.toString();
            }
            return '"' + escape(v.toString()) + '"';
        }

        private static String escape(String s) {
            return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
        }
    }
}
