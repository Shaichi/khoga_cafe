SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

DECLARE @store_id UNIQUEIDENTIFIER;
SELECT TOP 1 @store_id = id FROM stores;

IF @store_id IS NULL
BEGIN
    PRINT 'No store found!';
    RETURN;
END

DECLARE @cat_id UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, is_active, created_at, name) VALUES (@cat_id, 1, GETDATE(), N'Cà phê truyền thống');

DECLARE @item1_id UNIQUEIDENTIFIER = NEWID();
INSERT INTO menuitems (id, is_active, is_deleted, price, created_at, category_id, name, size_name, image_url)
VALUES (@item1_id, 1, 0, 35000, GETDATE(), @cat_id, N'Cà phê Sữa đá', 'M', 'https://bizweb.dktcdn.net/100/415/010/products/22.jpg');

INSERT INTO branchmenustatuss (id, is_available, created_at, menu_item_id, store_id)
VALUES (NEWID(), 1, GETDATE(), @item1_id, @store_id);

DECLARE @item2_id UNIQUEIDENTIFIER = NEWID();
INSERT INTO menuitems (id, is_active, is_deleted, price, created_at, category_id, name, size_name, image_url)
VALUES (@item2_id, 1, 0, 30000, GETDATE(), @cat_id, N'Cà phê Đen đá', 'M', 'https://bizweb.dktcdn.net/100/415/010/products/1-6cc89b4e-e179-43c2-bd5a-93f9c6d32ff8.jpg');

INSERT INTO branchmenustatuss (id, is_available, created_at, menu_item_id, store_id)
VALUES (NEWID(), 1, GETDATE(), @item2_id, @store_id);

DECLARE @cat2_id UNIQUEIDENTIFIER = NEWID();
INSERT INTO categorys (id, is_active, created_at, name) VALUES (@cat2_id, 1, GETDATE(), N'Trà trái cây');

DECLARE @item3_id UNIQUEIDENTIFIER = NEWID();
INSERT INTO menuitems (id, is_active, is_deleted, price, created_at, category_id, name, size_name, image_url)
VALUES (@item3_id, 1, 0, 45000, GETDATE(), @cat2_id, N'Trà Đào Cam Sả', 'M', 'https://bizweb.dktcdn.net/100/415/010/products/10-72eaaf48-038c-4f7f-a607-bbcd385d30cc.jpg');

INSERT INTO branchmenustatuss (id, is_available, created_at, menu_item_id, store_id)
VALUES (NEWID(), 1, GETDATE(), @item3_id, @store_id);

PRINT 'Menu seeded successfully!';
