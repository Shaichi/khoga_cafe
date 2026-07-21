USE khoga_coffee_shop;
GO

-- 1. Tạo Topping
DECLARE @topping1 UNIQUEIDENTIFIER = NEWID();
INSERT INTO optiontoppings (id, name, price, is_active, created_at, updated_at)
VALUES (@topping1, N'Trân châu trắng', 10000, 1, GETDATE(), GETDATE());

DECLARE @topping2 UNIQUEIDENTIFIER = NEWID();
INSERT INTO optiontoppings (id, name, price, is_active, created_at, updated_at)
VALUES (@topping2, N'Trân châu đen', 10000, 1, GETDATE(), GETDATE());

DECLARE @topping3 UNIQUEIDENTIFIER = NEWID();
INSERT INTO optiontoppings (id, name, price, is_active, created_at, updated_at)
VALUES (@topping3, N'Thạch đào', 15000, 1, GETDATE(), GETDATE());

DECLARE @topping4 UNIQUEIDENTIFIER = NEWID();
INSERT INTO optiontoppings (id, name, price, is_active, created_at, updated_at)
VALUES (@topping4, N'Kem Macchiato', 15000, 1, GETDATE(), GETDATE());

-- 2. Link topping với menu items (Tìm các món nước như Trà Vải, Trà Đào, Cà phê đen)
-- Biến chứa các món nước
DECLARE @itemId1 UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM menuitems WHERE name = N'Trà Vải Nhiệt Đới');
DECLARE @itemId2 UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM menuitems WHERE name = N'Trà Đào Cam Sả Đặc Biệt');
DECLARE @itemId3 UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM menuitems WHERE name = N'Cà phê sữa đá');

-- Map topping cho Trà Vải
IF @itemId1 IS NOT NULL
BEGIN
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId1, @topping1, GETDATE(), GETDATE());
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId1, @topping4, GETDATE(), GETDATE());
END

-- Map topping cho Trà Đào
IF @itemId2 IS NOT NULL
BEGIN
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId2, @topping3, GETDATE(), GETDATE());
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId2, @topping4, GETDATE(), GETDATE());
END

-- Map topping cho Cà phê sữa đá
IF @itemId3 IS NOT NULL
BEGIN
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId3, @topping2, GETDATE(), GETDATE());
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemId3, @topping4, GETDATE(), GETDATE());
END

PRINT 'Thêm Topping mẫu và link vào Menu thành công!';
GO
