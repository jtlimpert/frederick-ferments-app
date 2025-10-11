-- Migration: Make product_inventory_id optional in recipe_templates
-- This allows for intermediate steps and experimental recipes that don't produce a final product

-- Drop the existing index
DROP INDEX IF EXISTS idx_recipe_templates_product;

-- Alter the column to allow NULL values
ALTER TABLE recipe_templates
ALTER COLUMN product_inventory_id DROP NOT NULL;

-- Recreate the index with a WHERE clause to exclude NULL values (more efficient)
CREATE INDEX idx_recipe_templates_product ON recipe_templates(product_inventory_id)
WHERE product_inventory_id IS NOT NULL;
