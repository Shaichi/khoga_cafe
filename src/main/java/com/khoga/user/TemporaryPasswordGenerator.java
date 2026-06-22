package com.khoga.user;

import java.security.SecureRandom;

/**
 * Generates a 12-character random temporary password that satisfies the BR-14 policy (at least one
 * uppercase, lowercase, digit and special character). Ambiguous characters (0/O, 1/l/I) are omitted.
 */
final class TemporaryPasswordGenerator {

    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    private static final String LOWER = "abcdefghijkmnpqrstuvwxyz";
    private static final String DIGIT = "23456789";
    private static final String SPECIAL = "@#$%&*!?";
    private static final String ALL = UPPER + LOWER + DIGIT + SPECIAL;
    private static final int LENGTH = 12;

    private TemporaryPasswordGenerator() {
    }

    static String generate() {
        StringBuilder sb = new StringBuilder();
        sb.append(pick(UPPER)).append(pick(LOWER)).append(pick(DIGIT)).append(pick(SPECIAL));
        while (sb.length() < LENGTH) {
            sb.append(pick(ALL));
        }
        return shuffle(sb.toString());
    }

    private static char pick(String source) {
        return source.charAt(RANDOM.nextInt(source.length()));
    }

    private static String shuffle(String value) {
        char[] chars = value.toCharArray();
        for (int i = chars.length - 1; i > 0; i--) {
            int j = RANDOM.nextInt(i + 1);
            char tmp = chars[i];
            chars[i] = chars[j];
            chars[j] = tmp;
        }
        return new String(chars);
    }
}
