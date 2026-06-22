package com.khoga.catalog;

import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** P1.3 unit tests for BR-26 abbreviation generation + collision suffixing. */
class AbbreviationGeneratorTest {

    private final AbbreviationGenerator generator = new AbbreviationGenerator();

    @Test
    void multiWordTakesInitialsDiacriticFree() {
        assertEquals("cpd", generator.base("Cà phê đá"));
    }

    @Test
    void singleWordTakesFirstThreeLetters() {
        assertEquals("esp", generator.base("Espresso"));
    }

    @Test
    void uniqueAppendsNumericSuffixOnCollision() {
        Set<String> taken = Set.of("cpd", "cpd2");
        assertEquals("cpd3", generator.unique("Cà phê đá", taken::contains));
    }

    @Test
    void uniqueReturnsBaseWhenFree() {
        assertEquals("cpd", generator.unique("Cà phê đá", s -> false));
    }
}
