USE khoga_coffee_shop;
GO

-- Thêm chi nhánh mẫu
DECLARE @storeId UNIQUEIDENTIFIER = NEWID();
INSERT INTO stores (id, name, address, phone, is_active, created_at, updated_at)
VALUES (@storeId, N'Chi nhánh Quận 1', N'123 Nguyễn Huệ, Quận 1', '0901112222', 1, GETDATE(), GETDATE());

DECLARE @storeId2 UNIQUEIDENTIFIER = NEWID();
INSERT INTO stores (id, name, address, phone, is_active, created_at, updated_at)
VALUES (@storeId2, N'Chi nhánh Quận 7', N'456 Nguyễn Văn Linh, Quận 7', '0903334444', 1, GETDATE(), GETDATE());

-- Thêm danh mục
DECLARE @catTea UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, name, description, is_active, created_at, updated_at)
VALUES (@catTea, N'Trà Thanh Mát', N'Các loại trà trái cây', 1, GETDATE(), GETDATE());

DECLARE @catCake UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, name, description, is_active, created_at, updated_at)
VALUES (@catCake, N'Bánh Ngọt', N'Bánh dùng kèm cà phê', 1, GETDATE(), GETDATE());

-- Thêm sản phẩm
INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catTea, N'Trà Vải Nhiệt Đới', N'Trà vải ngâm thanh mát', 45000, 1, 0, GETDATE(), GETDATE());

INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catTea, N'Trà Đào Cam Sả Đặc Biệt', N'Size L', 55000, 1, 0, GETDATE(), GETDATE());

INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catCake, N'Bánh Tiramisu', N'Tiramisu kiểu Ý', 35000, 1, 0, GETDATE(), GETDATE());

INSERT INTO menuitems (id, category_id, name, description, price, is_active, is_deleted, created_at, updated_at)
VALUES (NEWID(), @catCake, N'Bánh Sừng Trâu', N'Croissant thơm bơ', 25000, 1, 0, GETDATE(), GETDATE());

PRINT 'Thêm dữ liệu mẫu thành công!';
GO
