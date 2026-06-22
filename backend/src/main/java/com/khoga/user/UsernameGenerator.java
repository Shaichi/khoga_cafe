package com.khoga.user;

import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.regex.Pattern;

/**
 * BR-58 username proposal: {@code [main-name lowercase][initials of family+middle, uppercase][sequence]},
 * with Vietnamese characters folded to the plain English alphabet.
 * Example: {@code "Nguyễn Văn An"} with sequence 43 → {@code "anNV43"}.
 */
@Component
public class UsernameGenerator {

    private static final Pattern COMBINING_MARKS = Pattern.compile("\\p{M}+");

    public String generate(String fullName, long sequence) {
        String ascii = toAscii(fullName).trim().replaceAll("\\s+", " ");
        if (ascii.isEmpty()) {
            return "user" + sequence;
        }
        String[] tokens = ascii.split(" ");
        String mainName = tokens[tokens.length - 1].toLowerCase();
        StringBuilder initials = new StringBuilder();
        for (int i = 0; i < tokens.length - 1; i++) {
            if (!tokens[i].isEmpty()) {
                initials.append(Character.toUpperCase(tokens[i].charAt(0)));
            }
        }
        return mainName + initials + sequence;
    }

    private static String toAscii(String input) {
        if (input == null) {
            return "";
        }
        String normalized = Normalizer.normalize(input, Normalizer.Form.NFD);
        normalized = COMBINING_MARKS.matcher(normalized).replaceAll("");
        return normalized
                .replace("đ", "d").replace("Đ", "D")
                .replaceAll("[^A-Za-z ]", "");
    }
}
