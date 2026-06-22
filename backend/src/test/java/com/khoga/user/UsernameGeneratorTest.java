package com.khoga.user;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** P1.2 unit tests for BR-58 username generation (the worked example + diacritic folding). */
class UsernameGeneratorTest {

    private final UsernameGenerator generator = new UsernameGenerator();

    @Test
    void generatesPerSpecWorkedExample() {
        assertEquals("anNV43", generator.generate("Nguyễn Văn An", 43));
    }

    @Test
    void usesAllMiddleAndFamilyInitials() {
        assertEquals("hangTTB7", generator.generate("Trần Thị Bích Hằng", 7));
    }

    @Test
    void foldsDjCharacter() {
        assertEquals("datDD1", generator.generate("Đỗ Đức Đạt", 1));
    }

    @Test
    void singleWordNameHasNoInitials() {
        assertEquals("madonna5", generator.generate("Madonna", 5));
    }

    @Test
    void blankNameFallsBackToSequence() {
        assertTrue(generator.generate("   ", 9).startsWith("user"));
    }
}
