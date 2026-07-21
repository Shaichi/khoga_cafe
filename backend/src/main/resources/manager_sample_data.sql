-- ==========================================================
-- Manager Flow Sample Data for Khoga Cafe
-- Contains data for: Categories, Menu Items, Raw Materials (Inventory), 
-- Stock Items, and Recipe Items.
-- Target DB: SQL Server
-- ==========================================================

-- 1. Get default Store ID (Assuming DataSeeder has run)
DECLARE @StoreId UNIQUEIDENTIFIER = (SELECT TOP 1 id FROM stores WHERE name = 'Khoga Flagship');

IF @StoreId IS NULL
BEGIN
    PRINT 'Default store not found. Please run the Spring Boot app once to let DataSeeder create the default store.';
    RETURN;
END

DECLARE @Now DATETIME = GETDATE();

-- ==========================================================
-- 2. Insert Categories
-- ==========================================================
DECLARE @CatCoffeeId UNIQUEIDENTIFIER = NEWID();
DECLARE @CatTeaId UNIQUEIDENTIFIER = NEWID();
DECLARE @CatFoodId UNIQUEIDENTIFIER = NEWID();

INSERT INTO categorys (id, name, description, is_active, created_at, updated_at) VALUES
(@CatCoffeeId, N'Cà phê', N'Các loại cà phê pha máy và pha phin', 1, @Now, @Now),
(@CatTeaId, N'Trà trái cây', N'Trà trái cây tươi mát', 1, @Now, @Now),
(@CatFoodId, N'Bánh ngọt', N'Bánh ngọt ăn kèm', 1, @Now, @Now);

-- ==========================================================
-- 3. Insert Raw Materials (Ingredients / Inventory)
-- ==========================================================
DECLARE @RawCoffeeId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawMilkId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawSugarId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawTeaId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawPeachId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawCakeId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawPlasticCupId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawPaperStrawId UNIQUEIDENTIFIER = NEWID();
DECLARE @RawCaramelSyrupId UNIQUEIDENTIFIER = NEWID();

INSERT INTO rawmaterials (id, code, name, unit, suggested_min_threshold, standard_cost, is_active, category, created_at, updated_at) VALUES
(@RawCoffeeId, N'RM-COF-01', N'Hạt cà phê Arabica', N'kg', 5.0, 250000.0, 1, N'Nguyên liệu chính', @Now, @Now),
(@RawMilkId, N'RM-MIL-01', N'Sữa đặc Ngôi Sao', N'hộp', 10.0, 20000.0, 1, N'Sữa & Đường', @Now, @Now),
(@RawSugarId, N'RM-SUG-01', N'Đường cát trắng', N'kg', 10.0, 25000.0, 1, N'Sữa & Đường', @Now, @Now),
(@RawTeaId, N'RM-TEA-01', N'Trà đen', N'kg', 3.0, 150000.0, 1, N'Nguyên liệu chính', @Now, @Now),
(@RawPeachId, N'RM-PEA-01', N'Đào ngâm đóng hộp', N'hộp', 5.0, 50000.0, 1, N'Trái cây', @Now, @Now),
(@RawCakeId, N'RM-CAK-01', N'Bánh Tiramisu (lát)', N'lát', 10.0, 15000.0, 1, N'Thành phẩm', @Now, @Now),
(@RawPlasticCupId, N'RM-CUP-01', N'Ly nhựa M', N'cái', 500.0, 1000.0, 1, N'Bao bì', @Now, @Now),
(@RawPaperStrawId, N'RM-STR-01', N'Ống hút giấy', N'cái', 1000.0, 500.0, 1, N'Bao bì', @Now, @Now),
(@RawCaramelSyrupId, N'RM-SYR-01', N'Siro Caramel', N'chai', 2.0, 120000.0, 1, N'Hương liệu', @Now, @Now);

-- ==========================================================
-- 4. Insert Stock Items (Current inventory for the store)
-- ==========================================================
INSERT INTO stockitems (id, store_id, raw_material_id, current_quantity, min_alert_threshold, created_at, updated_at) VALUES
(NEWID(), @StoreId, @RawCoffeeId, 20.0, 5.0, @Now, @Now),
(NEWID(), @StoreId, @RawMilkId, 50.0, 10.0, @Now, @Now),
(NEWID(), @StoreId, @RawSugarId, 30.0, 10.0, @Now, @Now),
(NEWID(), @StoreId, @RawTeaId, 15.0, 3.0, @Now, @Now),
(NEWID(), @StoreId, @RawPeachId, 20.0, 5.0, @Now, @Now),
(NEWID(), @StoreId, @RawCakeId, 15.0, 10.0, @Now, @Now),
(NEWID(), @StoreId, @RawPlasticCupId, 100.0, 500.0, @Now, @Now), -- Sắp hết
(NEWID(), @StoreId, @RawPaperStrawId, 150.0, 1000.0, @Now, @Now), -- Sắp hết
(NEWID(), @StoreId, @RawCaramelSyrupId, 1.0, 2.0, @Now, @Now); -- Sắp hết

-- ==========================================================
-- 5. Insert Menu Items (Products)
-- ==========================================================
DECLARE @MenuCaPheSuaId UNIQUEIDENTIFIER = NEWID();
DECLARE @MenuTraDaoId UNIQUEIDENTIFIER = NEWID();
DECLARE @MenuTiramisuId UNIQUEIDENTIFIER = NEWID();

INSERT INTO menuitems (id, category_id, name, price, description, is_active, is_deleted, sku, abbreviation, created_at, updated_at) VALUES
(@MenuCaPheSuaId, @CatCoffeeId, N'Cà phê sữa đá', 29000.0, N'Cà phê sữa pha phin truyền thống', 1, 0, N'CF-SUA-DA', N'CFSD', @Now, @Now),
(@MenuTraDaoId, @CatTeaId, N'Trà đào cam sả', 39000.0, N'Trà đào thanh mát với cam và sả', 1, 0, N'TR-DAO-CS', N'TDCS', @Now, @Now),
(@MenuTiramisuId, @CatFoodId, N'Bánh Tiramisu', 35000.0, N'Bánh Tiramisu phô mai', 1, 0, N'CAKE-TIRA', N'TIRA', @Now, @Now);

-- ==========================================================
-- 6. Insert Recipe Items (BOM - Bill of Materials)
-- ==========================================================
INSERT INTO recipeitems (id, menu_item_id, raw_material_id, quantity_required, created_at, updated_at) VALUES
(NEWID(), @MenuCaPheSuaId, @RawCoffeeId, 0.02, @Now, @Now), -- 20g cà phê
(NEWID(), @MenuCaPheSuaId, @RawMilkId, 0.5, @Now, @Now),    -- 0.5 hộp sữa
(NEWID(), @MenuTraDaoId, @RawTeaId, 0.015, @Now, @Now),     -- 15g trà
(NEWID(), @MenuTraDaoId, @RawPeachId, 0.2, @Now, @Now),     -- 1/5 hộp đào
(NEWID(), @MenuTraDaoId, @RawSugarId, 0.03, @Now, @Now),    -- 30g đường
(NEWID(), @MenuTiramisuId, @RawCakeId, 1.0, @Now, @Now);    -- 1 lát bánh

PRINT 'Sample data inserted successfully!';
