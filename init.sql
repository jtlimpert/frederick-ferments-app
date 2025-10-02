-- Frederick Ferments Database Schema
-- PostgreSQL initialization script

-- Create UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Suppliers table
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Inventory log table for tracking movements
CREATE TABLE inventory_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_id UUID NOT NULL REFERENCES inventory(id),
    movement_type VARCHAR NOT NULL, -- 'purchase', 'sale', 'adjustment', 'waste'
    quantity DECIMAL NOT NULL,
    unit_cost DECIMAL,
    reason TEXT,
    batch_number VARCHAR,
    expiry_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_inventory_active ON inventory(is_active);
CREATE INDEX idx_inventory_category ON inventory(category);
CREATE INDEX idx_inventory_supplier ON inventory(default_supplier_id);
CREATE INDEX idx_inventory_log_item ON inventory_log(inventory_id);
CREATE INDEX idx_inventory_log_date ON inventory_log(created_at);

-- Insert some sample data
-- Coordinates are for fictional locations in the Frederick, MD area
INSERT INTO suppliers (name, contact_email, contact_phone, address, latitude, longitude) VALUES
    ('Local Farm Supply', 'orders@localfarmsupply.com', '555-0123', '123 Farm Road, Frederick, MD 21701', 39.41427, -77.41054),
    ('Organic Ingredients Co', 'sales@organicingredients.com', '555-0456', '456 Market Street, Frederick, MD 21702', 39.43562, -77.43821),
    ('Valley Grains & More', 'info@valleygrains.com', '555-0789', '789 Valley Pike, Frederick, MD 21703', 39.38291, -77.38109);

INSERT INTO inventory (name, category, unit, current_stock, reorder_point, cost_per_unit) VALUES
    ('Organic Wheat Flour', 'Grains', 'lbs', 50.0, 10.0, 2.50),
    ('Sea Salt', 'Seasonings', 'lbs', 25.0, 5.0, 1.25),
    ('Active Dry Yeast', 'Fermentation', 'oz', 100.0, 20.0, 0.15);