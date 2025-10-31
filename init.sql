-- Frederick Ferments Database Schema
-- PostgreSQL initialization script
-- PostgreSQL 16 supports gen_random_uuid() natively (no extension needed)

-- Suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    contact_email VARCHAR,
    contact_phone VARCHAR,
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'USA',
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
    product_inventory_id UUID REFERENCES inventory(id),  -- Made nullable for intermediate/experimental recipes
    template_name VARCHAR(255) NOT NULL,
    description TEXT,
    default_batch_size DECIMAL(10,3),
    default_unit VARCHAR(50),
    estimated_duration_hours DECIMAL(6,2),
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

-- Customers table
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    street_address VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    country VARCHAR(100) DEFAULT 'USA',
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    customer_type VARCHAR(50) DEFAULT 'retail',
    tax_exempt BOOLEAN DEFAULT false,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sales table
CREATE TABLE sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number VARCHAR(100) NOT NULL UNIQUE,
    customer_id UUID REFERENCES customers(id),
    sale_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    payment_status VARCHAR(50) NOT NULL DEFAULT 'completed',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sale items table
CREATE TABLE sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
    inventory_id UUID NOT NULL REFERENCES inventory(id),
    quantity DECIMAL(10,3) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    notes TEXT
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
CREATE INDEX idx_recipe_templates_product ON recipe_templates(product_inventory_id) WHERE product_inventory_id IS NOT NULL;
CREATE INDEX idx_recipe_templates_active ON recipe_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_customers_name ON customers(name);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_active ON customers(is_active);
CREATE INDEX idx_sales_date ON sales(sale_date DESC);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_status ON sales(payment_status);
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_inventory ON sale_items(inventory_id);

-- ============================================================================
-- Sample Test Data
-- ============================================================================

-- Insert suppliers
INSERT INTO suppliers (id, name, contact_email, contact_phone, street_address, city, state, zip_code, country, latitude, longitude, notes, created_at, updated_at) VALUES
('75bf2f4b-d30d-4258-8b62-2937525a714f', 'Walmart', '', '', '2421 Monocacy Blvd,', 'Frederick', 'MD', '21701', 'USA', 39.449001, -77.386978, '', NOW(), NOW()),
('f0444eba-2b22-4ece-8303-f29764611009', 'Home Garden', '', '', '8 Fairview Ave', 'Frederick', 'MD', '21701', 'USA', 39.416313, -77.431301, '', NOW(), NOW());

-- Insert inventory items
INSERT INTO inventory (id, name, category, unit, current_stock, reserved_stock, reorder_point, cost_per_unit, default_supplier_id, shelf_life_days, storage_requirements, is_active, created_at, updated_at) VALUES
('fc8bc8a3-c8cf-4f05-b141-732aef691d63', 'Cabbage', 'Vegetable', 'grams', 0, 0, 100, NULL, '75bf2f4b-d30d-4258-8b62-2937525a714f', 14, 'Store in fridge', true, NOW(), NOW()),
('201721bd-29a3-4fd9-9b55-528e85838eba', 'Salt', 'minerial', 'grams', 0, 0, 20, NULL, '75bf2f4b-d30d-4258-8b62-2937525a714f', NULL, 'Keep dry', true, NOW(), NOW()),
('d7c62dd3-a545-44e1-81b6-4bbea8b9c8d5', 'Dill', 'Herb', 'grams', 0, 0, 10, NULL, 'f0444eba-2b22-4ece-8303-f29764611009', 14, 'Store in fridge', true, NOW(), NOW()),
('fa3a419d-8331-496f-8c25-a7dba9ac70fe', 'Garlic', 'Herb', 'grams', 0, 0, 10, NULL, 'f0444eba-2b22-4ece-8303-f29764611009', 265, 'Keep dry', true, NOW(), NOW()),
('999026a6-1941-44cd-9b27-119ad21e699a', 'Garlic Dill Sauerkraut', 'finished_product', 'grams', 0, 0, 100, NULL, NULL, NULL, '', true, NOW(), NOW());

-- Insert recipe templates
INSERT INTO recipe_templates (id, product_inventory_id, template_name, description, default_batch_size, default_unit, estimated_duration_hours, ingredient_template, instructions, is_active, created_at, updated_at) VALUES
('42feebfc-6dd4-41f2-9cf7-be9e5d8a185f', '999026a6-1941-44cd-9b27-119ad21e699a', 'Garlic Dill Sauerkraut', 'This is sauerkraut with garlic and dill', 1000.000, 'grams', 672.00,
'{"ingredients": [{"unit": "grams", "inventory_id": "fc8bc8a3-c8cf-4f05-b141-732aef691d63", "quantity_per_batch": 1000}, {"unit": "grams", "inventory_id": "201721bd-29a3-4fd9-9b55-528e85838eba", "quantity_per_batch": 20}, {"unit": "grams", "inventory_id": "d7c62dd3-a545-44e1-81b6-4bbea8b9c8d5", "quantity_per_batch": 5}, {"unit": "grams", "inventory_id": "fa3a419d-8331-496f-8c25-a7dba9ac70fe", "quantity_per_batch": 10}]}'::jsonb,
'Part 1: Roast the Garlic (Do This First)
Total Time: ~40 minutes + cooling

Gather Ingredients (5 minutes)

Collect 4 garlic cloves (leave unpeeled)


Roast (35 minutes)

Preheat oven to 400°F (204°C)
Place unpeeled garlic cloves on parchment paper
Roast for 35 minutes


Rest (until cool)

Remove from oven
Let cool completely until safe to handle


Prepare for Use

Once cooled, squeeze out the roasted garlic from the peels
Set aside for mixing with cabbage




Part 2: Make the Sauerkraut
Total Time: 30 minutes active + 28 days fermentation
Start Time: 9:00 AM

Step 1: Prepare Cabbage (9:00 AM - 10 minutes)

Clean the cabbage
Slice cabbage into thin strips
Important: Weigh the usable cabbage and record the weight
Note: You need this weight to calculate the correct salt amount


Step 2: Prepare Fresh Dill (9:10 AM - 5 minutes)

Rinse the fresh dill
Chop into small pieces
Set aside in a clean bowl


Step 3: Combine Ingredients and Massage (9:15 AM - 10 minutes)

Place sliced cabbage in a large mixing bowl
Add the roasted garlic (squeeze out from peels)
Add chopped fresh dill
Add salt
Important: Use 2% of the cabbage weight in salt
Example: For 1000g cabbage, use 20g salt


Begin massaging the mixture:

Use clean hands to squeeze and massage the cabbage
Continue for about 10 minutes
Goal: Break down the cabbage and release its natural juices



Step 4: Pack into Jar (9:25 AM - 5 minutes)

Transfer the cabbage mixture into a clean glass jar
Pack it down firmly with your fist or a clean utensil
Push out air pockets as you pack
Ensure the cabbage is submerged under its own liquid
Note: If liquid doesn''t cover the cabbage after packing, wait 24 hours for more juice to release


Step 5: Fermentation (9:30 AM - 28 days)

Cover the jar loosely (gas needs to escape)
Place jar on a plate (to catch any overflow)
Store at room temperature (65-75°F / 18-24°C)
Keep out of direct sunlight


Daily Maintenance:

Check daily for the first week
Press down cabbage if it rises above the liquid
Taste after 7 days, then every few days
Fermentation is complete when it reaches your desired tanginess (usually 3-4 weeks)


Completion:

When fermentation is complete, seal jar tightly
Transfer to refrigerator for long-term storage
Will keep for several months refrigerated',
true, NOW(), NOW());