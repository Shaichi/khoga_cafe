package com.khoga.branch.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record UpdateBranchRequest(
        @NotBlank(message = "Tên chi nhánh không được để trống") String name,
        @NotBlank(message = "Địa chỉ không được để trống") String address,
        @NotBlank @Pattern(regexp = "^[0-9]{10,12}$", message = "Số điện thoại phải có 10–12 chữ số") String phone) {
}
