USE khoga_coffee_shop;
GO

-- Xóa dữ liệu lỗi vừa insert (cách đây 30 phút)
DELETE FROM menu_item_topping_mappings WHERE created_at > DATEADD(minute, -30, GETDATE());
DELETE FROM optiontoppings WHERE created_at > DATEADD(minute, -30, GETDATE());
DELETE FROM menuitems WHERE created_at > DATEADD(minute, -30, GETDATE()) AND price IN (45000, 55000, 35000, 25000);
DELETE FROM categorys WHERE created_at > DATEADD(minute, -30, GETDATE()) AND is_active = 1;
DELETE FROM stores WHERE created_at > DATEADD(minute, -30, GETDATE()) AND id NOT IN (SELECT store_id FROM users);

-- Thêm lại chi nhánh mẫu
DECLARE @storeId UNIQUEIDENTIFIER = NEWID();
INSERT INTO stores (id, name, address, phone, is_active, created_at, updated_at)
VALUES (@storeId, N'Chi nhánh Quận 1', N'123 Nguyễn Huệ, Quận 1', '0901112222', 1, GETDATE(), GETDATE());

DECLARE @storeId2 UNIQUEIDENTIFIER = NEWID();
INSERT INTO stores (id, name, address, phone, is_active, created_at, updated_at)
VALUES (@storeId2, N'Chi nhánh Quận 7', N'456 Nguyễn Văn Linh, Quận 7', '0903334444', 1, GETDATE(), GETDATE());

-- Thêm lại danh mục
DECLARE @catTea UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, name, description, is_active, created_at, updated_at)
VALUES (@catTea, N'Trà Thanh Mát', N'Các loại trà trái cây', 1, GETDATE(), GETDATE());

DECLARE @catCake UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, name, description, is_active, created_at, updated_at)
VALUES (@catCake, N'Bánh Ngọt', N'Bánh dùng kèm cà phê', 1, GETDATE(), GETDATE());

-- Thêm lại sản phẩm
DECLARE @itemTraVai UNIQUEIDENTIFIER = NEWID();
INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (@itemTraVai, @catTea, N'Trà Vải Nhiệt Đới', N'Trà vải ngâm thanh mát', 45000, 1, 0, GETDATE(), GETDATE());

DECLARE @itemTraDao UNIQUEIDENTIFIER = NEWID();
INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (@itemTraDao, @catTea, N'Trà Đào Cam Sả Đặc Biệt', N'Size L', 55000, 1, 0, GETDATE(), GETDATE());

INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catCake, N'Bánh Tiramisu', N'Tiramisu kiểu Ý', 35000, 1, 0, GETDATE(), GETDATE());

INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catCake, N'Bánh Sừng Trâu', N'Croissant thơm bơ', 25000, 1, 0, GETDATE(), GETDATE());

-- 1. Tạo lại Topping
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

-- 2. Map lại topping cho các món mới (vì ID đã thay đổi)
DECLARE @itemCafeSua UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM menuitems WHERE name = N'Cà phê sữa đá');

-- Map topping cho Trà Vải
INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemTraVai, @topping1, GETDATE(), GETDATE());
INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemTraVai, @topping4, GETDATE(), GETDATE());

-- Map topping cho Trà Đào
INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemTraDao, @topping3, GETDATE(), GETDATE());
INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemTraDao, @topping4, GETDATE(), GETDATE());

-- Map topping cho Cà phê sữa đá (Cà phê sữa đá được tạo từ MockDataSeeder, tên không bị lỗi)
IF @itemCafeSua IS NOT NULL
BEGIN
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemCafeSua, @topping2, GETDATE(), GETDATE());
    INSERT INTO menu_item_topping_mappings (id, menu_item_id, option_topping_id, created_at, updated_at) VALUES (NEWID(), @itemCafeSua, @topping4, GETDATE(), GETDATE());
END

PRINT 'Sửa lỗi font và thêm lại dữ liệu thành công!';
GO
