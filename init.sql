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
-- Ready for your data!
-- ============================================================================
-- Database is initialized with schema and indexes only.
-- No sample data included - start fresh!