package com.khoga.catalog;

import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.function.Predicate;
import java.util.regex.Pattern;

/**
 * BR-26 menu-item abbreviation: lowercase first letters of the words in the diacritic-removed name
 * (single word → first three letters); on collision a numeric suffix is appended (cfd, cfd2, cfd3…).
 *
 * <p>Note: the spec's phonetic example "Cà phê đá" → "cfd" relies on a Vietnamese ph→f mapping that
 * is out of scope here; this implementation yields the plain-initials form "cpd".
 */
@Component
public class AbbreviationGenerator {

    private static final Pattern COMBINING_MARKS = Pattern.compile("\\p{M}+");

    public String base(String name) {
        String ascii = toAscii(name).trim().replaceAll("\\s+", " ").toLowerCase();
        if (ascii.isEmpty()) {
            return "itm";
        }
        String[] words = ascii.split(" ");
        if (words.length == 1) {
            String word = words[0];
            return word.length() <= 3 ? word : word.substring(0, 3);
        }
        StringBuilder sb = new StringBuilder();
        for (String word : words) {
            if (!word.isEmpty()) {
                sb.append(word.charAt(0));
            }
        }
        return sb.toString();
    }

    /** Returns a unique abbreviation, appending an incrementing suffix while {@code exists} is true. */
    public String unique(String name, Predicate<String> exists) {
        String base = base(name);
        if (!exists.test(base)) {
            return base;
        }
        int suffix = 2;
        while (exists.test(base + suffix)) {
            suffix++;
        }
        return base + suffix;
    }

    private static String toAscii(String input) {
        if (input == null) {
            return "";
        }
        String normalized = Normalizer.normalize(input, Normalizer.Form.NFD);
        normalized = COMBINING_MARKS.matcher(normalized).replaceAll("");
        return normalized.replace("đ", "d").replace("Đ", "D").replaceAll("[^A-Za-z ]", "");
    }
}
