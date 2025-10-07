-- Frederick Ferments Database Schema
-- PostgreSQL initialization script
-- PostgreSQL 16 supports gen_random_uuid() natively (no extension needed)

-- Suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    contact_email VARCHAR,
    contact_phone VARCHAR,
    address TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Inventory table
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    unit VARCHAR NOT NULL,
    current_stock DECIMAL NOT NULL DEFAULT 0,
    reserved_stock DECIMAL NOT NULL DEFAULT 0,
    available_stock DECIMAL GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,
    reorder_point DECIMAL NOT NULL DEFAULT 0,
    cost_per_unit DECIMAL,
    default_supplier_id UUID REFERENCES suppliers(id),
    shelf_life_days INTEGER,
    storage_requirements TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Inventory logs table for tracking movements
CREATE TABLE inventory_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_id UUID NOT NULL REFERENCES inventory(id),
    movement_type VARCHAR NOT NULL, -- 'purchase', 'sale', 'adjustment', 'waste'
    quantity DECIMAL NOT NULL,
    unit_cost DECIMAL,
    reason TEXT,
    batch_number VARCHAR,
    expiry_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Recipe templates table (must be created before production_batches due to foreign key)
CREATE TABLE recipe_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_inventory_id UUID NOT NULL REFERENCES inventory(id),
    template_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_batch_size DECIMAL(10,3),
    default_unit VARCHAR(50),
    estimated_duration_hours DECIMAL(6,2),
    reminder_schedule JSONB,
    ingredient_template JSONB,
    instructions TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Production batches table
CREATE TABLE production_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_number VARCHAR(100) NOT NULL UNIQUE,
    product_inventory_id UUID NOT NULL REFERENCES inventory(id),
    recipe_template_id UUID REFERENCES recipe_templates(id),
    batch_size DECIMAL(10,3) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estimated_completion_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    production_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    production_time_hours DECIMAL(6,2),
    yield_percentage DECIMAL(5,2),
    actual_yield DECIMAL(10,3),
    quality_notes TEXT,
    storage_location VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Production batch ingredients table
CREATE TABLE production_batch_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES production_batches(id) ON DELETE CASCADE,
    ingredient_inventory_id UUID NOT NULL REFERENCES inventory(id),
    quantity_used DECIMAL(10,3) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    notes TEXT
);

-- Production reminders table
CREATE TABLE production_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES production_batches(id) ON DELETE CASCADE,
    reminder_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    due_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    snoozed_until TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_inventory_active ON inventory(is_active);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_supplier ON inventory(default_supplier_id);
CREATE INDEX idx_inventory_logs_item ON inventory_logs(inventory_id);
CREATE INDEX idx_inventory_logs_date ON inventory_logs(created_at);
CREATE INDEX idx_production_batches_date ON production_batches(production_date DESC);
CREATE INDEX idx_production_batches_start_date ON production_batches(start_date DESC);
CREATE INDEX idx_production_batches_product ON production_batches(product_inventory_id);
CREATE INDEX idx_production_batches_status ON production_batches(status);
CREATE INDEX idx_production_batches_status_active ON production_batches(status, start_date DESC)
    WHERE status IN ('in_progress');
CREATE INDEX idx_production_batch_ingredients_batch ON production_batch_ingredients(batch_id);
CREATE INDEX idx_production_batch_ingredients_ingredient ON production_batch_ingredients(ingredient_inventory_id);
CREATE INDEX idx_recipe_templates_product ON recipe_templates(product_inventory_id);
CREATE INDEX idx_recipe_templates_active ON recipe_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_reminders_batch ON production_reminders(batch_id);
CREATE INDEX idx_reminders_due_pending ON production_reminders(due_at)
    WHERE completed_at IS NULL;

-- ============================================================================
-- Sample Data Inserts
-- ============================================================================

-- Insert sample suppliers
-- Coordinates are for fictional locations in the Frederick, MD area
INSERT INTO suppliers (name, contact_email, contact_phone, address, latitude, longitude) VALUES
    ('Local Farm Supply', 'orders@localfarmsupply.com', '555-0123', '123 Farm Road, Frederick, MD 21701', 39.41427, -77.41054),
    ('Organic Ingredients Co', 'sales@organicingredients.com', '555-0456', '456 Market Street, Frederick, MD 21702', 39.43562, -77.43821),
    ('Valley Grains & More', 'info@valleygrains.com', '555-0789', '789 Valley Pike, Frederick, MD 21703', 39.38291, -77.38109);

-- Insert sample inventory items
INSERT INTO inventory (name, category, unit, current_stock, reorder_point, cost_per_unit) VALUES
    ('Organic Wheat Flour', 'Grains', 'lbs', 50.0, 10.0, 2.50),
    ('Sea Salt', 'Seasonings', 'lbs', 25.0, 5.0, 1.25),
    ('Active Dry Yeast', 'Fermentation', 'oz', 100.0, 20.0, 0.15),
    ('Bread Flour', 'Flour', 'kg', 50.0, 10.0, 2.50),
    ('Whole Wheat Flour', 'Flour', 'kg', 30.0, 10.0, 3.00),
    ('Rye Flour', 'Flour', 'kg', 20.0, 5.0, 3.50),
    ('Sourdough Starter', 'Starter', 'kg', 3.0, 0.5, 0.00),
    ('Honey', 'Sweeteners', 'kg', 8.0, 2.0, 8.50),
    ('Olive Oil', 'Oils', 'L', 12.0, 3.0, 15.00),
    ('Filtered Water', 'Liquids', 'L', 100.0, 20.0, 0.00),
    ('Sesame Seeds', 'Toppings', 'kg', 4.0, 1.0, 6.00),
    ('Sourdough Bread', 'finished_product', 'loaves', 0.0, 5.0, NULL);

-- Insert sample recipe template for Sourdough Bread with ingredient template
INSERT INTO recipe_templates (
  product_inventory_id,
  template_name,
  description,
  default_batch_size,
  default_unit,
  estimated_duration_hours,
  reminder_schedule,
  ingredient_template
)
SELECT
  prod.id,
  'Basic Sourdough Bread',
  'Traditional sourdough bread with autolyse and multiple folds',
  2.0,
  'loaves',
  18.0,
  '{
    "reminders": [
      {"type": "autolyse", "message": "Autolyse rest complete - add starter and salt", "after_minutes": 30},
      {"type": "fold", "message": "First fold - stretch and fold the dough", "after_minutes": 60},
      {"type": "fold", "message": "Second fold", "after_minutes": 90},
      {"type": "shape", "message": "Bulk fermentation complete - shape loaves and cold proof", "after_hours": 4},
      {"type": "bake", "message": "Preheat oven to 450°F and prepare to bake", "after_hours": 16}
    ]
  }'::jsonb,
  jsonb_build_object(
    'ingredients', jsonb_agg(
      jsonb_build_object(
        'inventory_id', ing.id,
        'quantity_per_batch', ing.qty,
        'unit', ing.unit
      )
    )
  )
FROM inventory prod,
LATERAL (VALUES
  ((SELECT id FROM inventory WHERE name = 'Bread Flour'), 0.5, 'kg'),
  ((SELECT id FROM inventory WHERE name = 'Filtered Water'), 0.35, 'L'),
  ((SELECT id FROM inventory WHERE name = 'Sourdough Starter'), 0.1, 'kg'),
  ((SELECT id FROM inventory WHERE name = 'Sea Salt'), 0.01, 'lbs')
) AS ing(id, qty, unit)
WHERE prod.name = 'Sourdough Bread'
GROUP BY prod.id;