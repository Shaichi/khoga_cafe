package com.khoga.catalog;

import com.khoga.catalog.dto.RecipeLineRequest;
import com.khoga.catalog.dto.RecipeLineResponse;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.OptionTopping;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.RecipeItem;
import com.khoga.common.repository.RawMaterialRepository;
import com.khoga.common.repository.RecipeItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Recipe (RECIPE_ITEM) management shared by menu items and toppings (UC-18/19, §3.3.6). Enforces
 * BR-73: every line's unit must equal the referenced raw material's master unit (no conversion).
 */
@Service
public class RecipeService {

    private final RecipeItemRepository recipeItemRepository;
    private final RawMaterialRepository rawMaterialRepository;

    public RecipeService(RecipeItemRepository recipeItemRepository, RawMaterialRepository rawMaterialRepository) {
        this.recipeItemRepository = recipeItemRepository;
        this.rawMaterialRepository = rawMaterialRepository;
    }

    @Transactional
    public void replaceForMenuItem(MenuItem menuItem, List<RecipeLineRequest> lines) {
        recipeItemRepository.deleteByMenuItemId(menuItem.getId());
        if (lines == null) {
            return;
        }
        for (RecipeLineRequest line : lines) {
            RawMaterial material = validateLine(line);
            RecipeItem item = new RecipeItem();
            item.setMenuItem(menuItem);
            item.setRawMaterial(material);
            item.setQuantityRequired(line.quantity());
            recipeItemRepository.save(item);
        }
    }

    @Transactional
    public void replaceForTopping(OptionTopping topping, List<RecipeLineRequest> lines) {
        recipeItemRepository.deleteByOptionToppingId(topping.getId());
        if (lines == null) {
            return;
        }
        for (RecipeLineRequest line : lines) {
            RawMaterial material = validateLine(line);
            RecipeItem item = new RecipeItem();
            item.setOptionTopping(topping);
            item.setRawMaterial(material);
            item.setQuantityRequired(line.quantity());
            recipeItemRepository.save(item);
        }
    }

    @Transactional(readOnly = true)
    public List<RecipeLineResponse> menuItemRecipe(UUID menuItemId) {
        return recipeItemRepository.findByMenuItemId(menuItemId).stream()
                .map(CatalogMapper::toRecipeLineResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<RecipeLineResponse> toppingRecipe(UUID toppingId) {
        return recipeItemRepository.findByOptionToppingId(toppingId).stream()
                .map(CatalogMapper::toRecipeLineResponse).toList();
    }

    /** BR-73: unit must match the master unit exactly; the material must exist and be active. */
    private RawMaterial validateLine(RecipeLineRequest line) {
        RawMaterial material = rawMaterialRepository.findById(line.rawMaterialId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nguyên liệu"));
        if (Boolean.FALSE.equals(material.getIsActive())) {
            throw new AppException("Nguyên liệu '" + material.getName() + "' không còn hoạt động");
        }
        if (material.getUnit() == null || !material.getUnit().equalsIgnoreCase(line.unit())) {
            throw new AppException("Số lượng của '" + material.getName() + "' phải nhập theo đơn vị gốc ("
                    + material.getUnit() + "). Không hỗ trợ quy đổi đơn vị.");   // BR-73
        }
        return material;
    }
}
