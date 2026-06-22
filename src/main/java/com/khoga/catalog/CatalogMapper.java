package com.khoga.catalog;

import com.khoga.catalog.dto.CategoryResponse;
import com.khoga.catalog.dto.MenuItemDetailResponse;
import com.khoga.catalog.dto.MenuItemResponse;
import com.khoga.catalog.dto.RawMaterialResponse;
import com.khoga.catalog.dto.RecipeLineResponse;
import com.khoga.catalog.dto.ToppingResponse;
import com.khoga.common.model.Category;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.OptionTopping;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.RecipeItem;

import java.util.List;
import java.util.UUID;

/** Hand-written entity→DTO mappers for the catalog subsystem (project convention: no MapStruct). */
final class CatalogMapper {

    private CatalogMapper() {
    }

    static CategoryResponse toCategoryResponse(Category c) {
        return new CategoryResponse(c.getId(), c.getName(), c.getDescription(), Boolean.TRUE.equals(c.getIsActive()));
    }

    static MenuItemResponse toMenuItemResponse(MenuItem m) {
        return new MenuItemResponse(
                m.getId(), m.getName(), m.getPrice(),
                m.getCategory() != null ? m.getCategory().getId() : null,
                m.getCategory() != null ? m.getCategory().getName() : null,
                m.getAbbreviation(), m.getBarcode(),
                Boolean.TRUE.equals(m.getIsActive()), Boolean.TRUE.equals(m.getIsDeleted()));
    }

    static MenuItemDetailResponse toMenuItemDetail(MenuItem m, List<RecipeLineResponse> recipe,
                                                   List<ToppingResponse> toppings) {
        return new MenuItemDetailResponse(
                m.getId(), m.getName(), m.getPrice(),
                m.getCategory() != null ? m.getCategory().getId() : null,
                m.getCategory() != null ? m.getCategory().getName() : null,
                m.getAbbreviation(), m.getBarcode(), m.getDescription(), m.getImageUrl(),
                Boolean.TRUE.equals(m.getIsActive()), Boolean.TRUE.equals(m.getIsDeleted()),
                recipe, toppings);
    }

    static ToppingResponse toToppingResponse(OptionTopping t, List<RecipeLineResponse> recipe) {
        return new ToppingResponse(t.getId(), t.getName(), t.getPrice(),
                Boolean.TRUE.equals(t.getIsActive()), recipe);
    }

    static RecipeLineResponse toRecipeLineResponse(RecipeItem ri) {
        RawMaterial rm = ri.getRawMaterial();
        UUID rmId = rm != null ? rm.getId() : null;
        String rmName = rm != null ? rm.getName() : null;
        String unit = rm != null ? rm.getUnit() : null;
        return new RecipeLineResponse(rmId, rmName, ri.getQuantityRequired(), unit);
    }

    static RawMaterialResponse toRawMaterialResponse(RawMaterial rm) {
        return new RawMaterialResponse(
                rm.getId(), rm.getCode(), rm.getName(), rm.getUnit(),
                rm.getSuggestedMinThreshold(), rm.getStandardCost(), rm.getCategory(),
                Boolean.TRUE.equals(rm.getIsActive()));
    }
}
