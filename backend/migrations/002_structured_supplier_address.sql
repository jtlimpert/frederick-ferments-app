-- Migration: Add structured address fields to suppliers table
-- This replaces the single 'address' text field with:
--   - street_address (street number + name)
--   - city
--   - state (2-letter code)
--   - zip_code
--   - country (defaults to USA)

-- Step 1: Add new structured address columns
ALTER TABLE suppliers
  ADD COLUMN street_address VARCHAR(255),
  ADD COLUMN city VARCHAR(100),
  ADD COLUMN state VARCHAR(2),
  ADD COLUMN zip_code VARCHAR(10),
  ADD COLUMN country VARCHAR(100) DEFAULT 'USA';

-- Step 2: Migrate existing 'address' data to 'street_address' (best effort)
-- This preserves existing data - users can edit to structure it properly
UPDATE suppliers
SET street_address = address
WHERE address IS NOT NULL;

-- Step 3: Drop the old 'address' column
ALTER TABLE suppliers
  DROP COLUMN address;

-- Note: Existing suppliers will have data in street_address only
-- Users should edit these suppliers to properly structure the address
