package com.khoga.common.dto;

import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PageResponseTest {

    @Test
    void of_mapsSpringDataPageFields() {
        Page<String> page = new PageImpl<>(List.of("a", "b"), PageRequest.of(0, 20), 2);

        PageResponse<String> response = PageResponse.of(page);

        assertEquals(List.of("a", "b"), response.getContent());
        assertEquals(0, response.getPage());
        assertEquals(20, response.getSize());
        assertEquals(2, response.getTotalElements());
        assertEquals(1, response.getTotalPages());
        assertTrue(response.isLast());
    }
}
