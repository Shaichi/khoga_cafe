USE khoga_coffee_shop;
GO
DELETE FROM menu_item_topping_mappings WHERE menu_item_id IN (SELECT id FROM menuitems WHERE name LIKE N'%Ã%');
DELETE FROM menuitems WHERE name LIKE N'%Ã%';
DELETE FROM categorys WHERE name LIKE N'%Ã%';
DELETE FROM stores WHERE name LIKE N'%Ã%';
GO
