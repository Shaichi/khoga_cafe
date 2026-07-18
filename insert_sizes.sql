USE khoga_coffee_shop;
GO

-- Lấy danh mục "Trà Thanh Mát" để dùng chung
DECLARE @catTea UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM categorys WHERE name = N'Trà Thanh Mát');

IF @catTea IS NOT NULL
BEGIN
    -- 1. Trà Sữa Oolong Nướng (Món gốc - để gom nhóm)
    DECLARE @parentOolong UNIQUEIDENTIFIER = NEWID();
    INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
    VALUES (@parentOolong, @catTea, N'Trà Sữa Oolong Nướng', N'Trà sữa oolong rang đậm vị', 0, 1, 0, GETDATE(), GETDATE());

    -- Size M
    DECLARE @oolongM UNIQUEIDENTIFIER = NEWID();
    INSERT INTO menuitems (id, category_id, parent_item_id, name, size_name, description, price, is_active, is_deleted, created_at, updated_at)
    VALUES (@oolongM, @catTea, @parentOolong, N'Trà Sữa Oolong Nướng', N'M', N'Size Vừa', 40000, 1, 0, GETDATE(), GETDATE());

    -- Size L
    DECLARE @oolongL UNIQUEIDENTIFIER = NEWID();
    INSERT INTO menuitems (id, category_id, parent_item_id, name, size_name, description, price, is_active, is_deleted, created_at, updated_at)
    VALUES (@oolongL, @catTea, @parentOolong, N'Trà Sữa Oolong Nướng', N'L', N'Size Lớn', 50000, 1, 0, GETDATE(), GETDATE());
    
    -- Lấy ID của Trân châu đen và Trân châu trắng có sẵn để gán vào làm Topping
    DECLARE @toppingDen UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM optiontoppings WHERE name = N'Trân châu đen');
    DECLARE @toppingTrang UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM optiontoppings WHERE name = N'Trân châu trắng');

    IF @toppingDen IS NOT NULL
    BEGIN
        INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @oolongM, @toppingDen, GETDATE(), GETDATE());
        INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @oolongL, @toppingDen, GETDATE(), GETDATE());
    END

    IF @toppingTrang IS NOT NULL
    BEGIN
        INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @oolongM, @toppingTrang, GETDATE(), GETDATE());
        INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @oolongL, @toppingTrang, GETDATE(), GETDATE());
    END
END

PRINT 'Thêm dữ liệu Size thành công!';
GO
