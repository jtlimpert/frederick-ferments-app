# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

Frederick Ferments is a fermentation business inventory management system built with:

- **Backend**: Rust GraphQL API using async-graphql (v7.0.17) and Axum (v0.8.4)
- **Database**: PostgreSQL 16 with SQLx for type-safe queries
- **Frontend**: Flutter (cross-platform: iOS, Android, Web, macOS, Windows, Linux)
- **State Management**: Riverpod for Flutter
- **Deployment**: Docker Compose setup with health checks
- **Runtime**: Tokio async runtime

The system tracks inventory items with fields for stock levels, reorder points, suppliers (with geographic coordinates), purchase history, and production batches. The GraphQL API provides queries for inventory, suppliers, production batches, and recipe templates, with mutations for full CRUD operations on inventory items, suppliers, and recipe templates, as well as purchases and production batch management. The Flutter frontend provides adaptive UI (bottom navigation for mobile, side rail for web/desktop) with four main screens: Inventory, Production, Recipes, and Suppliers.

### Key Components

**Backend Structure:**
- `backend/src/main.rs`: Main server entry point with GraphQL schema setup and connection pooling (max 10 connections)
- `backend/src/models/inventory.rs`: Core data models (InventoryItem, Supplier, inputs/outputs for CRUD operations)
- `backend/src/models/production.rs`: Production data models (ProductionBatch, RecipeTemplate, inputs/outputs)
- `backend/src/resolvers/query.rs`: GraphQL query resolvers (inventory_items, suppliers, active_batches, production_history, recipe_templates, recipe_template, health_check, ping)
- `backend/src/resolvers/mutation.rs`: GraphQL mutation resolvers (1,168 lines):
  - Inventory: create_inventory_item, update_inventory_item, delete_inventory_item
  - Suppliers: create_supplier, update_supplier
  - Recipe Templates: create_recipe_template, update_recipe_template, delete_recipe_template
  - Production: create_production_batch, complete_production_batch, fail_production_batch
  - Purchases: create_purchase
- `backend/Cargo.toml`: Dependencies configuration
- `migrations/`: Database migration files

**Frontend Structure:**
- `frontend/lib/main.dart`: App entry point with theme configuration
- `frontend/lib/screens/home_screen.dart`: Adaptive navigation wrapper (4 tabs: Inventory, Production, Recipes, Suppliers)
- `frontend/lib/screens/inventory_list_screen.dart`: Inventory list with stock status indicators and CRUD actions
- `frontend/lib/screens/inventory_item_form_screen.dart`: Create/edit inventory items
- `frontend/lib/screens/production_screen.dart`: Production management (active batches, "what can I make?", history)
- `frontend/lib/screens/create_production_batch_screen.dart`: Create new production batch with recipe template support
- `frontend/lib/screens/complete_production_batch_screen.dart`: Complete batch with yield tracking
- `frontend/lib/screens/create_purchase_screen.dart`: Record purchases from suppliers
- `frontend/lib/screens/recipes_screen.dart`: Recipe templates list with CRUD actions
- `frontend/lib/screens/recipe_template_form_screen.dart`: Create/edit recipe templates with ingredient management
- `frontend/lib/screens/suppliers_screen.dart`: Suppliers list with CRUD actions
- `frontend/lib/screens/supplier_form_screen.dart`: Create/edit suppliers with structured address fields
- `frontend/lib/models/`: Data models (InventoryItem, Supplier, ProductionBatch, RecipeTemplate, Purchase)
- `frontend/lib/services/`: GraphQL service and Riverpod providers
- `frontend/lib/widgets/`: Reusable UI components (InventoryItemCard)

**Infrastructure:**
- `docker-compose.yml`: Complete deployment stack with PostgreSQL and API containers
- `init.sql`: Database schema initialization with sample data (Frederick, MD locations)

### Database Schema

**Tables:**

1. **suppliers** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `name`: VARCHAR (NOT NULL)
   - `contact_email`, `contact_phone`, `notes`: Optional fields
   - **Structured Address Fields** (all optional):
     - `street_address`: VARCHAR(255) - Street address line
     - `city`: VARCHAR(100) - City name
     - `state`: VARCHAR(2) - Two-letter state code (e.g., MD)
     - `zip_code`: VARCHAR(10) - ZIP/postal code
     - `country`: VARCHAR(100) - Country name (defaults to USA)
   - `latitude`: DECIMAL(10, 8) (nullable) - Latitude for map display
   - `longitude`: DECIMAL(11, 8) (nullable) - Longitude for map display
   - `created_at`, `updated_at`: TIMESTAMPTZ (auto-managed)

2. **inventory** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `name`, `category`, `unit`: VARCHAR (NOT NULL)
   - `current_stock`: DECIMAL (NOT NULL, default 0)
   - `reserved_stock`: DECIMAL (NOT NULL, default 0)
   - `available_stock`: DECIMAL (GENERATED ALWAYS AS `current_stock - reserved_stock` STORED)
   - `reorder_point`: DECIMAL (NOT NULL, default 0)
   - `cost_per_unit`: DECIMAL (nullable)
   - `default_supplier_id`: UUID (foreign key to suppliers, nullable)
   - `shelf_life_days`: INTEGER (nullable)
   - `storage_requirements`: TEXT (nullable)
   - `is_active`: BOOLEAN (NOT NULL, default true)
   - `created_at`, `updated_at`: TIMESTAMPTZ (auto-managed)

3. **inventory_logs** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `inventory_id`: UUID (foreign key to inventory, NOT NULL)
   - `movement_type`: VARCHAR (NOT NULL) - values: 'purchase', 'sale', 'adjustment', 'waste', 'production_use', 'production_output'
   - `quantity`: DECIMAL (NOT NULL)
   - `unit_cost`: DECIMAL (nullable)
   - `reason`: TEXT (nullable)
   - `batch_number`: VARCHAR (nullable)
   - `expiry_date`: DATE (nullable)
   - `created_at`: TIMESTAMPTZ (auto-managed)

4. **recipe_templates** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `product_inventory_id`: UUID (foreign key to inventory, **nullable**) - Optional link to finished product; allows experimental/intermediate recipes
   - `template_name`: VARCHAR(255) (NOT NULL)
   - `description`: TEXT (nullable)
   - `default_batch_size`: DECIMAL(10,3) (nullable)
   - `default_unit`: VARCHAR(50) (nullable)
   - `estimated_duration_hours`: DECIMAL(6,2) (nullable)
   - `ingredient_template`: JSONB (nullable) - Format: `{"ingredients": [{"inventory_id": "uuid", "quantity_per_batch": number, "unit": "string"}]}`
   - `instructions`: TEXT (nullable)
   - `is_active`: BOOLEAN (default true)
   - `created_at`, `updated_at`: TIMESTAMPTZ (auto-managed)

5. **production_batches** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `batch_number`: VARCHAR(100) (NOT NULL, UNIQUE) - Auto-generated format: `BATCH-YYYYMMDD-NNN`
   - `product_inventory_id`: UUID (foreign key to inventory, NOT NULL)
   - `recipe_template_id`: UUID (foreign key to recipe_templates, nullable)
   - `batch_size`: DECIMAL(10,3) (NOT NULL)
   - `unit`: VARCHAR(50) (NOT NULL)
   - `start_date`: TIMESTAMPTZ (NOT NULL, default NOW())
   - `estimated_completion_date`: TIMESTAMPTZ (nullable)
   - `completion_date`: TIMESTAMPTZ (nullable)
   - `production_date`: TIMESTAMPTZ (NOT NULL, default NOW())
   - `status`: VARCHAR(50) (NOT NULL, default 'in_progress') - values: 'in_progress', 'completed', 'failed'
   - `production_time_hours`: DECIMAL(6,2) (nullable) - Auto-calculated on completion
   - `yield_percentage`: DECIMAL(5,2) (nullable) - Auto-calculated: `(actual_yield / batch_size) * 100`
   - `actual_yield`: DECIMAL(10,3) (nullable) - Set on completion
   - `quality_notes`: TEXT (nullable)
   - `storage_location`: VARCHAR(100) (nullable)
   - `notes`: TEXT (nullable)
   - `created_at`, `updated_at`: TIMESTAMPTZ (auto-managed)

6. **production_batch_ingredients** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `batch_id`: UUID (foreign key to production_batches, NOT NULL, CASCADE DELETE)
   - `ingredient_inventory_id`: UUID (foreign key to inventory, NOT NULL)
   - `quantity_used`: DECIMAL(10,3) (NOT NULL)
   - `unit`: VARCHAR(50) (NOT NULL)
   - `notes`: TEXT (nullable)

**Note:** The `production_reminders` table exists in the database schema but is not currently used by the application. It was removed in a recent update for simplification.

**Indexes:**
- `idx_inventory_active` on inventory(is_active)
- `idx_inventory_category` on inventory(category)
- `idx_inventory_supplier` on inventory(default_supplier_id)
- `idx_inventory_logs_item` on inventory_logs(inventory_id)
- `idx_inventory_logs_date` on inventory_logs(created_at)
- `idx_production_batches_date` on production_batches(production_date DESC)
- `idx_production_batches_start_date` on production_batches(start_date DESC)
- `idx_production_batches_product` on production_batches(product_inventory_id)
- `idx_production_batches_status` on production_batches(status)
- `idx_production_batches_status_active` on production_batches(status, start_date DESC) WHERE status IN ('in_progress')
- `idx_production_batch_ingredients_batch` on production_batch_ingredients(batch_id)
- `idx_production_batch_ingredients_ingredient` on production_batch_ingredients(ingredient_inventory_id)
- `idx_recipe_templates_product` on recipe_templates(product_inventory_id)
- `idx_recipe_templates_active` on recipe_templates(is_active) WHERE is_active = true

## Development Commands

### Quick Start (Recommended)

**VSCode Task (Easiest):**
- Press `Cmd+Shift+P` → "Tasks: Run Task" → "🚀 Start Full Dev Environment (Recommended)"
- Or press `Cmd+Shift+B` (default build task)

**Manual Script:**
```bash
./scripts/dev-start.sh
```

This script automatically:
1. Starts the database if not running
2. Waits for database to be healthy
3. Checks and regenerates SQLx cache if needed
4. Builds and starts the full Docker stack
5. Waits for API to be ready

### Local Development
```bash
# Start the full stack
docker-compose up

# Start just the database
docker-compose up db

# Run the Rust API locally (requires local PostgreSQL)
cd backend
cargo run

# Build the API
cd backend
cargo build

# Run tests
cd backend
cargo test
```

### Database Management
```bash
# Reset database (stops containers and removes volumes)
docker-compose down -v

# View database logs
docker-compose logs db

# Connect to database
docker exec -it frederick-ferments-db psql -U postgres -d frederick_ferments
```

### API Development
```bash
# Check Rust code formatting
cd backend
cargo fmt --check

# Run clippy linting
cd backend
cargo clippy

# Update dependencies
cd backend
cargo update

# Update SQLx offline cache (after changing SQL queries or schema)
cd backend
cargo sqlx prepare
# Then commit: git add .sqlx && git commit -m "Update SQLx cache"
```

**About SQLx Offline Mode:**
- The backend uses `SQLX_OFFLINE=true` to enable Docker builds without a database connection
- Query metadata is cached in `backend/.sqlx/` directory (committed to git)
- Update the cache whenever you:
  - Change SQL queries in the code
  - Add/modify database columns
  - Change Rust structs that map to database tables
- The `dev-start.sh` script automatically checks and updates the cache

### Flutter Development
```bash
# Run Flutter app (auto-selects device)
cd frontend
flutter run

# Run on specific platform
flutter run -d chrome         # Web
flutter run -d macos          # macOS
flutter run -d ios            # iOS Simulator
flutter run -d android        # Android Emulator

# Generate Riverpod code after model changes
cd frontend
dart run build_runner build --delete-conflicting-outputs

# Get/update dependencies
flutter pub get

# Clean build artifacts
flutter clean

# Run tests
flutter test

# VSCode Tasks (Cmd+Shift+P -> Tasks: Run Task)
# - Flutter: Run (Select Device)
# - Flutter: Run Web
# - Flutter: Run macOS
# - Flutter: Run iOS Simulator
# - Flutter: Stop All Devices
```

## GraphQL API

The API runs on port 4000 with:
- **GraphQL endpoint**: `http://localhost:4000/graphql` (POST)
- **GraphiQL playground**: `http://localhost:4000/graphql` (GET/browser)
- **CORS**: Permissive mode (allows all origins)

### Data Structures

**Core Rust Models** (`backend/src/models/inventory.rs`):

```rust
// Main inventory item structure
pub struct InventoryItem {
    pub id: Uuid,
    pub name: String,
    pub category: String,
    pub unit: String,
    pub current_stock: BigDecimal,           // Total physical stock
    pub reserved_stock: BigDecimal,          // Stock allocated but not yet used
    pub available_stock: BigDecimal,         // Computed: current - reserved
    pub reorder_point: BigDecimal,           // When to reorder
    pub cost_per_unit: Option<BigDecimal>,   // Current unit cost
    pub default_supplier_id: Option<Uuid>,   // Preferred supplier
    pub shelf_life_days: Option<i32>,        // Days until expiry
    pub storage_requirements: Option<String>,// Storage notes
    pub is_active: bool,                     // Soft delete flag
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Supplier information
pub struct Supplier {
    pub id: Uuid,
    pub name: String,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub street_address: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip_code: Option<String>,
    pub country: Option<String>,
    pub latitude: Option<BigDecimal>,
    pub longitude: Option<BigDecimal>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Production batch
pub struct ProductionBatch {
    pub id: Uuid,
    pub batch_number: String,              // Auto-generated: BATCH-YYYYMMDD-NNN
    pub product_inventory_id: Uuid,
    pub recipe_template_id: Option<Uuid>,
    pub batch_size: BigDecimal,
    pub unit: String,
    pub start_date: DateTime<Utc>,
    pub estimated_completion_date: Option<DateTime<Utc>>,
    pub completion_date: Option<DateTime<Utc>>,
    pub production_date: DateTime<Utc>,
    pub status: String,                    // 'in_progress', 'completed', 'failed'
    pub production_time_hours: Option<BigDecimal>,
    pub yield_percentage: Option<BigDecimal>,
    pub actual_yield: Option<BigDecimal>,
    pub quality_notes: Option<String>,
    pub storage_location: Option<String>,
    pub notes: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Recipe template
pub struct RecipeTemplate {
    pub id: Uuid,
    pub product_inventory_id: Option<Uuid>,  // Optional - supports experimental/intermediate recipes
    pub template_name: String,
    pub description: Option<String>,
    pub default_batch_size: Option<BigDecimal>,
    pub default_unit: Option<String>,
    pub estimated_duration_hours: Option<BigDecimal>,
    pub ingredient_template: Option<serde_json::Value>, // JSONB
    pub instructions: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// Purchase operation input
pub struct CreatePurchaseInput {
    pub supplier_id: Uuid,
    pub items: Vec<PurchaseItemInput>,
    pub purchase_date: Option<DateTime<Utc>>, // Defaults to now
    pub notes: Option<String>,
}

pub struct PurchaseItemInput {
    pub inventory_id: Uuid,
    pub quantity: BigDecimal,
    pub unit_cost: BigDecimal,
    pub expiry_date: Option<NaiveDate>,
    pub batch_number: Option<String>,
}

// Purchase operation result
pub struct PurchaseResult {
    pub success: bool,
    pub message: String,
    pub updated_items: Vec<InventoryItem>,
}

// Production batch creation input
pub struct CreateProductionBatchInput {
    pub product_inventory_id: Uuid,
    pub recipe_template_id: Option<Uuid>,
    pub batch_size: BigDecimal,
    pub unit: String,
    pub estimated_completion_date: Option<DateTime<Utc>>,
    pub storage_location: Option<String>,
    pub notes: Option<String>,
    pub ingredients: Vec<IngredientInput>,
}

pub struct IngredientInput {
    pub inventory_id: Uuid,
    pub quantity_used: BigDecimal,
}

// Production batch completion input
pub struct CompleteProductionBatchInput {
    pub batch_id: Uuid,
    pub actual_yield: BigDecimal,
    pub quality_notes: Option<String>,
}

// Production batch failure input
pub struct FailProductionBatchInput {
    pub batch_id: Uuid,
    pub reason: String,
}

// Production batch operation result
pub struct ProductionBatchResult {
    pub success: bool,
    pub message: String,
    pub batch_id: Option<Uuid>,
    pub batch_number: Option<String>,
}
```

### Available Queries

**1. Health Check** (`backend/src/resolvers/query.rs:22`)
```graphql
query {
  healthCheck {
    status              # "healthy" or "unhealthy"
    timestamp           # Current server time
    databaseConnected   # Boolean connection status
    version             # Cargo package version
    uptimeSeconds       # Server uptime
  }
}
```

**2. Ping** (`backend/src/resolvers/query.rs:50`)
```graphql
query {
  ping  # Returns "pong"
}
```

**3. Get All Inventory Items** (`backend/src/resolvers/query.rs:54`)
```graphql
query {
  inventoryItems {
    id
    name
    category
    unit
    currentStock
    reservedStock
    availableStock      # Auto-calculated
    reorderPoint
    costPerUnit
    defaultSupplierId
    shelfLifeDays
    storageRequirements
    isActive
    createdAt
    updatedAt
  }
}
```
- Only returns items where `is_active = true`
- Ordered by name alphabetically

**4. Get All Suppliers** (`backend/src/resolvers/query.rs:82`)
```graphql
query {
  suppliers {
    id
    name
    contactEmail
    contactPhone
    address
    latitude
    longitude
    notes
    createdAt
    updatedAt
  }
}
```
- Ordered by name alphabetically

**5. Get Active Production Batches** (`backend/src/resolvers/query.rs:96`)
```graphql
query {
  activeBatches {
    id
    batchNumber
    productInventoryId
    recipeTemplateId
    batchSize
    unit
    startDate
    estimatedCompletionDate
    status
    storageLocation
    notes
    createdAt
  }
}
```
- Only returns batches with `status = 'in_progress'`
- Ordered by start_date DESC

**6. Get Production History** (`backend/src/resolvers/query.rs:150`)
```graphql
query {
  productionHistory(
    productInventoryId: "uuid-here"  # Optional filter by product
    limit: 20                         # Optional, default 50, max 500
  ) {
    id
    batchNumber
    productInventoryId
    batchSize
    unit
    startDate
    completionDate
    status
    yieldPercentage
    actualYield
    productionTimeHours
    qualityNotes
  }
}
```
- Ordered by start_date DESC
- Shows all statuses (in_progress, completed, failed)

**7. Get Recipe Templates** (`backend/src/resolvers/query.rs:205`)
```graphql
query {
  recipeTemplates {
    id
    productInventoryId
    templateName
    description
    defaultBatchSize
    defaultUnit
    estimatedDurationHours
    ingredientTemplate    # JSONB with ingredient ratios
    instructions
    isActive
    createdAt
  }
}
```
- Only returns active templates (`is_active = true`)
- Ordered by template_name

### Available Mutations

**1. Create Purchase** (`backend/src/resolvers/mutation.rs:13`)
```graphql
mutation {
  createPurchase(input: {
    supplierId: "uuid-here"
    purchaseDate: "2025-09-30T12:00:00Z"  # Optional, defaults to now
    notes: "Monthly restock"               # Optional
    items: [
      {
        inventoryId: "uuid-here"
        quantity: "50.5"
        unitCost: "2.75"
        expiryDate: "2025-12-31"           # Optional
        batchNumber: "BATCH-2025-001"      # Optional
      }
    ]
  }) {
    success
    message
    updatedItems {
      id
      name
      currentStock
      availableStock
      costPerUnit
    }
  }
}
```

**Purchase Flow** (`backend/src/resolvers/mutation.rs:17-99`):
1. Begins database transaction
2. For each item in purchase:
   - Inserts entry into `inventory_logs` table with movement_type='purchase'
   - Updates `inventory` table: increments `current_stock`, updates `cost_per_unit`
3. Commits transaction (atomic - all succeed or all fail)
4. Returns success status and updated inventory items

**Key Behaviors:**
- All operations are transactional (rollback on any error)
- Stock updates are additive: `current_stock = current_stock + quantity`
- Cost is updated to the most recent purchase price
- Audit trail maintained in `inventory_logs`

**2. Create Production Batch** (`backend/src/resolvers/mutation.rs:102`)
```graphql
mutation {
  createProductionBatch(input: {
    productInventoryId: "uuid-here"
    recipeTemplateId: "uuid-here"        # Optional
    batchSize: 2.0
    unit: "loaves"
    estimatedCompletionDate: "2025-10-12T12:00:00Z"  # Optional
    storageLocation: "Fridge #2"         # Optional
    notes: "Using starter from last week" # Optional
    ingredients: [
      {
        inventoryId: "uuid-here"
        quantityUsed: 0.5
      }
    ]
  }) {
    success
    message
    batchId
    batchNumber    # Auto-generated: BATCH-20251010-001
  }
}
```

**Production Batch Creation Flow** (`backend/src/resolvers/mutation.rs:102-308`):
1. Validates batch size > 0 and at least one ingredient
2. Validates product exists and is active
3. Validates all ingredients exist and have sufficient stock
4. Generates unique batch number (BATCH-YYYYMMDD-NNN)
5. Creates production_batches record with status='in_progress'
6. For each ingredient:
   - Creates production_batch_ingredients record
   - Decrements ingredient stock
   - Logs consumption in inventory_logs (movement_type='production_use')
7. Commits transaction
8. Returns batch ID and number

**3. Complete Production Batch** (`backend/src/resolvers/mutation.rs:311`)
```graphql
mutation {
  completeProductionBatch(input: {
    batchId: "uuid-here"
    actualYield: 1.8              # Actual units produced
    qualityNotes: "Perfect rise!" # Optional
  }) {
    success
    message
    batchId
    batchNumber
  }
}
```

**Completion Flow** (`backend/src/resolvers/mutation.rs:311-423`):
1. Validates batch exists and status is 'in_progress'
2. Calculates yield_percentage: (actual_yield / batch_size) * 100
3. Calculates production_time_hours from start_date to now
4. Updates batch: status='completed', adds yield metrics
5. Adds finished product to inventory (increments current_stock)
6. Logs production output in inventory_logs (movement_type='production_output')
7. Commits transaction

**4. Fail Production Batch** (`backend/src/resolvers/mutation.rs:426`)
```graphql
mutation {
  failProductionBatch(input: {
    batchId: "uuid-here"
    reason: "Starter wasn't active"
  }) {
    success
    message
    batchId
    batchNumber
  }
}
```

**Failure Flow** (`backend/src/resolvers/mutation.rs:426-493`):
1. Validates batch exists and status is 'in_progress'
2. Updates batch: status='failed', sets completion_date, adds reason to quality_notes
3. Does NOT refund ingredients (they were consumed)
4. Does NOT add finished product to inventory
5. Commits transaction

**5. Delete Inventory Item** (`backend/src/resolvers/mutation.rs:497`)
```graphql
mutation {
  deleteInventoryItem(input: {
    inventoryId: "uuid-here"
  }) {
    success
    message
  }
}
```

**Deletion Flow** (`backend/src/resolvers/mutation.rs:713-779`):
1. Validates item exists
2. Checks for active production batches using this item as ingredient
3. If active batches exist, returns error (prevents deletion)
4. Hard deletes item from inventory table
5. Cascading deletes handle related records
6. Commits transaction

**6. Create Inventory Item** (`backend/src/resolvers/mutation.rs:498`)
```graphql
mutation {
  createInventoryItem(input: {
    name: "Organic Wheat Flour"
    category: "ingredient"
    unit: "kg"
    reorderPoint: 10.0
    costPerUnit: 2.50
    defaultSupplierId: "uuid-here"  # Optional
    shelfLifeDays: 180              # Optional
    storageRequirements: "Cool, dry place"  # Optional
  }) {
    success
    message
    item {
      id
      name
      category
      currentStock
    }
  }
}
```
- Creates new inventory item with initial stock of 0
- All fields except name, category, and unit are optional
- Returns created item on success

**7. Update Inventory Item** (`backend/src/resolvers/mutation.rs:591`)
```graphql
mutation {
  updateInventoryItem(input: {
    inventoryId: "uuid-here"
    name: "Premium Wheat Flour"     # Optional
    category: "ingredient"          # Optional
    reorderPoint: 15.0              # Optional
    costPerUnit: 3.00               # Optional
    defaultSupplierId: "uuid-here"  # Optional
    shelfLifeDays: 180              # Optional
    storageRequirements: "Cool, dry place"  # Optional
  }) {
    success
    message
    item {
      id
      name
      costPerUnit
      reorderPoint
    }
  }
}
```
- Updates only provided fields (partial update)
- Cannot update stock levels directly (use purchases/production)
- Returns updated item on success

**8. Create Supplier** (`backend/src/resolvers/mutation.rs:781`)
```graphql
mutation {
  createSupplier(input: {
    name: "Local Farm Co-op"
    contactEmail: "orders@localfarm.coop"
    contactPhone: "+1-555-0123"
    streetAddress: "123 Farm Road"
    city: "Frederick"
    state: "MD"
    zipCode: "21701"
    country: "USA"
    latitude: 39.4143
    longitude: -77.4105
    notes: "Organic certified, delivers Tuesday/Friday"
  }) {
    success
    message
    supplier {
      id
      name
      contactEmail
      city
      state
    }
  }
}
```
- Creates new supplier with structured address fields
- All fields except name are optional
- Latitude/longitude enable map display
- Returns created supplier on success

**9. Update Supplier** (`backend/src/resolvers/mutation.rs:851`)
```graphql
mutation {
  updateSupplier(input: {
    supplierId: "uuid-here"
    name: "Local Farm Co-op & Market"  # Optional
    contactEmail: "orders@localfarm.coop"  # Optional
    contactPhone: "+1-555-0199"       # Optional
    streetAddress: "456 New Location" # Optional
    city: "Frederick"                 # Optional
    state: "MD"                       # Optional
    zipCode: "21702"                  # Optional
    country: "USA"                    # Optional
    latitude: 39.4200                 # Optional
    longitude: -77.4200               # Optional
    notes: "New location, same great service"  # Optional
  }) {
    success
    message
    supplier {
      id
      name
      streetAddress
      city
    }
  }
}
```
- Updates only provided fields (partial update)
- All fields except supplierId are optional
- Returns updated supplier on success

**10. Create Recipe Template** (`backend/src/resolvers/mutation.rs:955`)
```graphql
mutation {
  createRecipeTemplate(input: {
    productInventoryId: "uuid-here"  # Optional - supports experimental recipes
    templateName: "Sourdough Bread - Basic"
    description: "Traditional sourdough with long fermentation"
    defaultBatchSize: 2.0
    defaultUnit: "loaves"
    estimatedDurationHours: 24.0
    ingredientTemplate: {
      ingredients: [
        {
          inventory_id: "flour-uuid"
          quantity_per_batch: 1.0
          unit: "kg"
        },
        {
          inventory_id: "starter-uuid"
          quantity_per_batch: 0.2
          unit: "kg"
        }
      ]
    }
    instructions: "1. Mix ingredients\n2. Autolyse 30min\n3. Bulk ferment 12hrs..."
  }) {
    success
    message
    recipeTemplate {
      id
      templateName
      productInventoryId
    }
  }
}
```
- Creates new recipe template
- productInventoryId is optional (supports experimental/intermediate recipes)
- ingredientTemplate is JSONB format with ingredient ratios
- Returns created template on success

**11. Update Recipe Template** (`backend/src/resolvers/mutation.rs:1019`)
```graphql
mutation {
  updateRecipeTemplate(input: {
    recipeTemplateId: "uuid-here"
    templateName: "Sourdough Bread - Improved"  # Optional
    description: "Enhanced with better rise"     # Optional
    defaultBatchSize: 3.0                        # Optional
    defaultUnit: "loaves"                        # Optional
    estimatedDurationHours: 20.0                 # Optional
    ingredientTemplate: { ... }                  # Optional
    instructions: "Updated instructions..."      # Optional
  }) {
    success
    message
    recipeTemplate {
      id
      templateName
    }
  }
}
```
- Updates only provided fields (partial update)
- All fields except recipeTemplateId are optional
- Returns updated template on success

**12. Delete Recipe Template** (`backend/src/resolvers/mutation.rs:1106`)
```graphql
mutation {
  deleteRecipeTemplate(input: {
    recipeTemplateId: "uuid-here"
  }) {
    success
    message
  }
}
```
- Soft delete: sets is_active = false
- Template remains in database but hidden from queries
- Returns success status

## Environment Configuration

The backend uses these environment variables (`backend/src/main.rs:40-41`):
- `DATABASE_URL`: PostgreSQL connection string
  - Default: `postgresql://postgres:postgres@localhost:5432/frederick_ferments`
  - Docker: `postgresql://postgres:postgres@db:5432/frederick_ferments`
- `RUST_LOG`: Logging level (set to `info` in Docker)
- `PORT`: API server port (hardcoded to 4000 in `main.rs:63`)

Environment variables can be set in `backend/.env` for local development (loaded via `dotenvy`).

## System Architecture Flow

### Application Startup Flow (`backend/src/main.rs:37-66`)
1. Load environment variables from `.env` file (if exists)
2. Get `DATABASE_URL` from env or use default
3. Create PostgreSQL connection pool (max 10 connections)
4. Build GraphQL schema with QueryRoot, MutationRoot, and pool as context data
5. Create Axum router with:
   - GET `/graphql` → GraphiQL playground
   - POST `/graphql` → GraphQL handler
   - CORS layer (permissive)
   - Schema extension layer
6. Bind to `0.0.0.0:4000` and start server

### Request Flow
1. Client sends GraphQL query/mutation to `POST /graphql`
2. `graphql_handler` extracts schema from Axum extension (`main.rs:28`)
3. Schema executes resolver with PgPool from context
4. Resolver queries PostgreSQL using SQLx type-safe macros
5. Results serialized to JSON and returned

### Database Connection
- **Pool**: PostgreSQL connection pool with max 10 connections (`main.rs:44-47`)
- **Type Safety**: SQLx compile-time verified queries with `query_as!` macro
- **Transaction Support**: Explicit transaction handling with `pool.begin()` and `tx.commit()`

### Docker Deployment Flow
1. `docker-compose up` starts services:
   - **db service**: PostgreSQL 16 on port 5432
     - Runs `init.sql` on first startup to create schema and sample data
     - Health check: `pg_isready` every 10s
   - **api service**: Waits for db health check, then starts Rust API
     - Builds from `backend/DockerFile`
     - Health check: GraphQL ping query every 30s
2. API connects to database via internal Docker network
3. Both services expose ports to host machine (5432, 4000)

## Key Implementation Notes

### BigDecimal Usage
All quantity and cost fields use `BigDecimal` for precise decimal arithmetic (avoid floating-point rounding errors).

### UUID Generation
All IDs are UUIDs generated by PostgreSQL's `uuid_generate_v4()` function.

### Soft Deletes
Inventory items use `is_active` flag instead of hard deletes. Queries filter by `is_active = true`.

### Generated Columns
`available_stock` is computed automatically by PostgreSQL: `current_stock - reserved_stock`

### Audit Trail
All inventory movements are logged in `inventory_logs` table with movement_type, quantity, cost, and timestamps.

### Error Handling
- GraphQL resolvers return `async_graphql::Result` type
- Database errors propagate as GraphQL errors
- Transactions ensure atomic operations (all-or-nothing)

---

## Frontend Development (Flutter)

Frederick Ferments uses Flutter for cross-platform frontend development with the following stack:

- **Framework**: Flutter with Dart SDK 3.9.2+
- **State Management**: Riverpod (flutter_riverpod)
- **GraphQL Client**: graphql_flutter
- **Platforms**: iOS, Android, Web, macOS, Linux, Windows

### Flutter Development Guidelines

#### Interaction Guidelines
* **User Persona:** Assume the user is familiar with programming concepts but may be new to Dart.
* **Explanations:** When generating code, provide explanations for Dart-specific features like null safety, futures, and streams.
* **Clarification:** If a request is ambiguous, ask for clarification on the intended functionality and the target platform.
* **Dependencies:** When suggesting new dependencies from `pub.dev`, explain their benefits.
* **Formatting:** Use the `dart format` tool to ensure consistent code formatting.
* **Fixes:** Use the `dart fix` tool to automatically fix common errors and conform to configured analysis options.
* **Linting:** Use the Dart linter with recommended rules. Use the `analyze_files` tool to run the linter.

#### Project Structure
* **Standard Structure:** Assumes a standard Flutter project structure with `lib/main.dart` as the primary application entry point.
* **Logical Layers:** Organize the project into logical layers:
    * `lib/screens/` - Presentation (widgets, screens)
    * `lib/models/` - Domain (business logic classes, data models)
    * `lib/services/` - Data (API clients, repositories)
    * `lib/widgets/` - Shared/reusable widgets
    * `lib/core/` - Shared classes, utilities, and extension types (if needed)

#### Flutter Style Guide
* **SOLID Principles:** Apply SOLID principles throughout the codebase.
* **Concise and Declarative:** Write concise, modern, technical Dart code. Prefer functional and declarative patterns.
* **Composition over Inheritance:** Favor composition for building complex widgets and logic.
* **Immutability:** Prefer immutable data structures. Widgets (especially `StatelessWidget`) should be immutable.
* **State Management:** Separate ephemeral state and app state. Use Riverpod for app state to handle separation of concerns.
* **Widgets are for UI:** Everything in Flutter's UI is a widget. Compose complex UIs from smaller, reusable widgets.
* **Navigation:** Use a modern routing package like `go_router` for navigation.

#### Package Management
* **Pub Tool:** To manage packages, use the `pub` tool if available.
* **External Packages:** Identify the most suitable and stable package from pub.dev.
* **Adding Dependencies:** Run `flutter pub add <package_name>` for regular dependencies.
* **Adding Dev Dependencies:** Run `flutter pub add dev:<package_name>` for dev dependencies.
* **Dependency Overrides:** Run `flutter pub add override:<package_name>:1.0.0` for overrides.
* **Removing Dependencies:** Run `flutter pub remove <package_name>`.

#### Code Quality
* **Code Structure:** Adhere to maintainable code structure and separation of concerns (e.g., UI logic separate from business logic).
* **Naming Conventions:** Avoid abbreviations and use meaningful, consistent, descriptive names for variables, functions, and classes.
* **Conciseness:** Write code that is as short as it can be while remaining clear.
* **Simplicity:** Write straightforward code. Code that is clever or obscure is difficult to maintain.
* **Error Handling:** Anticipate and handle potential errors. Don't let your code fail silently.
* **Styling:**
    * Line length: Lines should be 80 characters or fewer.
    * Use `PascalCase` for classes, `camelCase` for members/variables/functions/enums, and `snake_case` for files.
* **Functions:** Functions short and with a single purpose (strive for less than 20 lines).
* **Testing:** Write code with testing in mind. Use the `file`, `process`, and `platform` packages so you can inject in-memory and fake versions.
* **Logging:** Use the `log` function from `dart:developer` for structured logging instead of `print`.

#### Dart Best Practices
* **Effective Dart:** Follow the official Effective Dart guidelines (https://dart.dev/effective-dart)
* **Class Organization:** Define related classes within the same library file. For large libraries, export smaller, private libraries from a single top-level library.
* **Library Organization:** Group related libraries in the same folder.
* **API Documentation:** Add documentation comments to all public APIs, including classes, constructors, methods, and top-level functions.
* **Comments:** Write clear comments for complex or non-obvious code. Avoid over-commenting.
* **Trailing Comments:** Don't add trailing comments.
* **Async/Await:** Ensure proper use of `async`/`await` for asynchronous operations with robust error handling.
    * Use `Future`s, `async`, and `await` for asynchronous operations.
    * Use `Stream`s for sequences of asynchronous events.
* **Null Safety:** Write code that is soundly null-safe. Leverage Dart's null safety features. Avoid `!` unless the value is guaranteed to be non-null.
* **Pattern Matching:** Use pattern matching features where they simplify the code.
* **Records:** Use records to return multiple types in situations where defining an entire class is cumbersome.
* **Switch Statements:** Prefer using exhaustive `switch` statements or expressions, which don't require `break` statements.
* **Exception Handling:** Use `try-catch` blocks for handling exceptions. Use custom exceptions for situations specific to your code.
* **Arrow Functions:** Use arrow syntax for simple one-line functions.

#### Flutter Best Practices
* **Immutability:** Widgets (especially `StatelessWidget`) are immutable; when the UI needs to change, Flutter rebuilds the widget tree.
* **Composition:** Prefer composing smaller widgets over extending existing ones. Use this to avoid deep widget nesting.
* **Private Widgets:** Use small, private `Widget` classes instead of private helper methods that return a `Widget`.
* **Build Methods:** Break down large `build()` methods into smaller, reusable private Widget classes.
* **List Performance:** Use `ListView.builder` or `SliverList` for long lists to create lazy-loaded lists for performance.
* **Isolates:** Use `compute()` to run expensive calculations in a separate isolate to avoid blocking the UI thread, such as JSON parsing.
* **Const Constructors:** Use `const` constructors for widgets and in `build()` methods whenever possible to reduce rebuilds.
* **Build Method Performance:** Avoid performing expensive operations, like network calls or complex computations, directly within `build()` methods.

#### State Management (Riverpod)
* **Riverpod:** Use Riverpod for state management as the primary solution in this project.
* **Providers:** Define providers for services, repositories, and state objects.
* **ConsumerWidget:** Use `ConsumerWidget` or `ConsumerStatefulWidget` to access providers.
* **Dependency Injection:** Use Riverpod's provider system for dependency injection.

#### Routing (go_router)
* **GoRouter:** Use `go_router` package for declarative navigation, deep linking, and web support.
* **Route Definition:** Define routes with path parameters and nested routes.
* **Authentication Redirects:** Configure `redirect` property to handle authentication flows.
* **Navigator:** Use built-in `Navigator` for short-lived screens like dialogs.

#### Data Handling & Serialization
* **JSON Serialization:** Use `json_serializable` and `json_annotation` for parsing and encoding JSON data.
* **Field Naming:** Use `fieldRename: FieldRename.snake` when backend uses snake_case but only if needed (GraphQL typically uses camelCase).

#### Logging
* **Structured Logging:** Use the `log` function from `dart:developer` for structured logging that integrates with Dart DevTools.

```dart
import 'dart:developer' as developer;

// For simple messages
developer.log('User logged in successfully.');

// For structured error logging
try {
  // ... code that might fail
} catch (e, s) {
  developer.log(
    'Failed to fetch data',
    name: 'myapp.network',
    level: 1000, // SEVERE
    error: e,
    stackTrace: s,
  );
}
```

#### Code Generation
* **Build Runner:** If the project uses code generation, ensure `build_runner` is listed as a dev dependency.
* **Running Build Runner:** After modifying files that require code generation, run:
  ```shell
  dart run build_runner build --delete-conflicting-outputs
  ```

#### Testing
* **Running Tests:** Use `flutter test` to run tests.
* **Unit Tests:** Use `package:test` for unit tests.
* **Widget Tests:** Use `package:flutter_test` for widget tests.
* **Integration Tests:** Use `package:integration_test` for integration tests.
* **Assertions:** Prefer using `package:checks` for more expressive assertions over default `matchers`.
* **Convention:** Follow the Arrange-Act-Assert (or Given-When-Then) pattern.
* **Mocks:** Prefer fakes or stubs over mocks. If mocks are necessary, use `mockito` or `mocktail`.
* **Coverage:** Aim for high test coverage.

#### Visual Design & Theming
* **UI Design:** Build beautiful and intuitive user interfaces that follow modern design guidelines.
* **Responsiveness:** Ensure the app is mobile responsive and adapts to different screen sizes, working perfectly on mobile and web.
* **Navigation:** Provide intuitive and easy navigation bar or controls.
* **Typography:** Stress and emphasize font sizes to ease understanding (hero text, section headlines, list headlines, keywords).
* **Background:** Apply subtle noise texture to the main background to add a premium, tactile feel.
* **Shadows:** Multi-layered drop shadows create a strong sense of depth; cards have a soft, deep shadow to look "lifted."
* **Icons:** Incorporate icons to enhance user understanding and logical navigation.
* **Interactive Elements:** Buttons, checkboxes, sliders, lists, charts have shadows with elegant use of color to create a "glow" effect.

#### Theming
* **Centralized Theme:** Define a centralized `ThemeData` object to ensure consistent application-wide style.
* **Light and Dark Themes:** Implement support for both light and dark themes (`ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`).
* **Color Scheme Generation:** Generate harmonious color palettes from a single color using `ColorScheme.fromSeed`.
* **Component Themes:** Use specific theme properties (e.g., `appBarTheme`, `elevatedButtonTheme`) to customize individual Material components.
* **Custom Fonts:** For custom fonts, use the `google_fonts` package. Define a `TextTheme` to apply fonts consistently.

#### Assets and Images
* **Image Guidelines:** Use relevant and meaningful images with appropriate size, layout, and licensing.
* **Asset Declaration:** Declare all asset paths in `pubspec.yaml`.
* **Local Images:** Use `Image.asset` for local images from asset bundle.
* **Network Images:** Use `Image.network` with `loadingBuilder` and `errorBuilder` for better UX.
* **Cached Images:** Use `cached_network_image` package for cached network images.
* **Custom Icons:** Use `ImageIcon` to display icons from an `ImageProvider`.

#### Layout Best Practices
* **Flexible Layouts:** Use `Expanded` to make a child widget fill remaining space, or `Flexible` for shrink-to-fit behavior.
* **Wrap:** Use `Wrap` when widgets would overflow a `Row` or `Column`.
* **SingleChildScrollView:** Use when content is intrinsically larger than viewport but is a fixed size.
* **ListView/GridView:** Always use builder constructors (`.builder`) for long lists/grids.
* **FittedBox:** Use to scale or fit a single child widget within its parent.
* **LayoutBuilder:** Use for complex, responsive layouts to make decisions based on available space.
* **Stack:** Use `Positioned` to precisely place children, or `Align` for alignment-based positioning.
* **OverlayPortal:** Use to show UI elements "on top" of everything else.

#### Color Scheme Best Practices
* **WCAG Guidelines:** Aim to meet Web Content Accessibility Guidelines (WCAG) 2.1 standards.
* **Minimum Contrast:** 4.5:1 for normal text, 3:1 for large text (18pt or 14pt bold).
* **Palette Selection:** Define clear color hierarchy (Primary, Secondary, Accent).
* **60-30-10 Rule:** 60% Primary/Neutral, 30% Secondary, 10% Accent.
* **Complementary Colors:** Use with caution for accents, avoid for text/background.

#### Font Best Practices
* **Font Selection:** Stick to one or two font families. Prioritize legibility. Sans-serif fonts preferred for UI body text.
* **Hierarchy and Scale:** Define font sizes for different text elements. Use font weight to differentiate.
* **Readability:** Line height 1.4x-1.6x the font size. Line length 45-75 characters for body text. Avoid all caps for long-form text.

#### Documentation
* **dartdoc:** Write `dartdoc`-style comments for all public APIs using `///`.
* **Comment Wisely:** Explain why code is written a certain way, not what it does.
* **Document for the User:** Write with the reader in mind.
* **No Useless Documentation:** Don't restate the obvious from code's name.
* **Consistency:** Use consistent terminology throughout documentation.

#### Accessibility (A11Y)
* **Color Contrast:** Ensure text has contrast ratio of at least 4.5:1 against background.
* **Dynamic Text Scaling:** Test UI remains usable when users increase system font size.
* **Semantic Labels:** Use `Semantics` widget to provide clear, descriptive labels for UI elements.
* **Screen Reader Testing:** Regularly test with TalkBack (Android) and VoiceOver (iOS).

#### Lint Rules
Include the following in `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # Add additional lint rules here as needed
```
---

## Flutter App Architecture

### Current Features

**Adaptive Navigation:**
- **Mobile (< 640px width)**: Bottom navigation bar with 4 tabs (Inventory, Production, Recipes, Suppliers)
- **Web/Desktop (≥ 640px width)**: Side navigation rail for better desktop UX
- Automatically adapts based on screen width using `LayoutBuilder`

**Inventory Screen:**
- Lists all active inventory items with pull-to-refresh
- Color-coded stock status indicators:
  - 🟢 Green (healthy): Stock above 120% of reorder point
  - 🟠 Orange (low): Stock between reorder point and 120% of reorder point
  - 🔴 Red (critical): Stock at or below reorder point
- Shows available stock, reserved stock, cost per unit, and category
- Progress bars visualizing stock levels
- Floating action button to add new inventory items
- Edit/delete actions for each item
- Record purchases from suppliers
- Material 3 design with cards and elevation

**Production Screen** ([production_screen.dart:14](frontend/lib/screens/production_screen.dart#L14)):
- **Section 1: In Progress Batches**
  - Shows all active production batches (status='in_progress')
  - Displays batch number, size, unit, and time since start
  - Actions: Complete batch or mark as failed
  - Refreshes data automatically after actions
- **Section 2: "What Can I Make?"**
  - Lists all finished products (category='finished_product')
  - Shows current stock levels
  - Quick "Make" button to start production batch
  - Pre-selects product when navigating to create batch screen
- **Section 3: Recent Batches**
  - Production history (last 10 batches by default)
  - Shows status (completed/failed/in_progress) with color-coded chips
  - Displays yield percentage for completed batches
  - Color-coded yield indicators (green: ≥90%, yellow: 70-89%, red: <70%)
- Pull-to-refresh support
- Floating action button to start new production batch

**Create Production Batch Screen** ([create_production_batch_screen.dart:11](frontend/lib/screens/create_production_batch_screen.dart#L11)):
- Product selection dropdown (finished products only)
- Optional recipe template selection (filtered by selected product)
- Pre-fills batch size and ingredient quantities from template
- Shows recipe description when template selected
- Ingredient input section with all non-finished-product inventory items
- Shows current stock availability for each ingredient
- Storage location and notes fields
- Validates batch size > 0 and at least one ingredient
- Creates batch and consumes ingredients atomically

**Complete Production Batch Screen** ([complete_production_batch_screen.dart](frontend/lib/screens/complete_production_batch_screen.dart)):
- Shows batch details (batch number, product, expected size)
- Actual yield input field
- Quality notes (optional)
- Calculates and displays yield percentage
- Adds finished product to inventory on completion
- Automatically updates production time and yield metrics

**Recipes Screen:**
- Lists all active recipe templates with pull-to-refresh
- Shows template name, description, and linked product (if any)
- Displays default batch size and estimated duration
- Floating action button to create new recipe templates
- Edit/delete actions for each recipe template
- Supports recipes without linked products (experimental/intermediate recipes)
- Shows ingredient count and estimated duration at a glance

**Recipe Template Form Screen:**
- Create or edit recipe templates
- Optional product selection (can be independent recipe)
- Template name, description, and instructions fields
- Default batch size and unit inputs
- Estimated duration in hours
- Ingredient management:
  - Add/remove ingredients from inventory
  - Specify quantity per batch for each ingredient
  - Shows current stock availability
- Form validation for required fields
- Material 3 design with consistent styling

**Suppliers Screen:**
- Lists all suppliers with pull-to-refresh
- Shows contact information (email, phone)
- Displays structured address fields (street, city, state, zip, country)
- Shows geographic coordinates when available
- Indicates suppliers with/without coordinates via icons
- Floating action button to add new suppliers
- Edit actions for each supplier
- **Planned**: Map view with supplier pins (toggle between list/map)

**Supplier Form Screen:**
- Create or edit supplier information
- Name and contact fields (email, phone)
- Structured address inputs:
  - Street address
  - City, state, zip code
  - Country (defaults to USA)
- Geographic coordinates (latitude/longitude) for map display
- Notes field for additional information
- Form validation for required fields

**Platform-Aware GraphQL Client:**
- Automatically selects correct endpoint based on platform:
  - Android emulator: `http://10.0.2.2:4000/graphql` (special host IP)
  - iOS/macOS/Web: `http://localhost:4000/graphql`
- Handles BigDecimal to double conversion for numeric fields from backend

### State Management

**Riverpod Providers:**
- `graphqlClientProvider`: Provides configured GraphQL client
- `graphqlServiceProvider`: Service layer for GraphQL operations
- `inventoryItemsProvider`: Async provider for inventory items list
- `suppliersProvider`: Async provider for suppliers list
- `activeBatchesProvider`: Async provider for in-progress production batches
- `productionHistoryProvider`: Async provider for production history (accepts productInventoryId and limit)
- `finishedProductsProvider`: Async provider for finished products (category='finished_product')
- `recipeTemplatesProvider`: Async provider for active recipe templates

**Code Generation:**
Run `dart run build_runner build --delete-conflicting-outputs` after modifying:
- Riverpod providers (`@riverpod` annotations)
- Model classes with serialization

### Data Models

**InventoryItem** (`frontend/lib/models/inventory_item.dart`):
- Handles all inventory fields including stock levels, costs, supplier relationships
- `needsReorder` computed property for low stock detection
- Parses BigDecimal string/number from GraphQL flexibly

**Supplier** (`frontend/lib/models/supplier.dart`):
- Includes latitude/longitude for map display
- `hasCoordinates` helper to check if supplier can be shown on map
- Parses BigDecimal coordinates from GraphQL

**ProductionBatch** (`frontend/lib/models/production_batch.dart`):
- Full production batch lifecycle tracking
- Status field: 'in_progress', 'completed', 'failed'
- Yield metrics: actual_yield, yield_percentage, production_time_hours
- Links to product and optional recipe template

**RecipeTemplate** (`frontend/lib/models/recipe_template.dart`):
- Template name, description, instructions
- Default batch size and estimated duration
- JSONB ingredient_template with ingredient ratios
- Optional link to product inventory item (supports experimental/intermediate recipes)
- Includes CreateRecipeTemplateInput and UpdateRecipeTemplateInput classes

### Implemented Features ✅

- ✅ Full inventory management with stock status indicators
- ✅ Inventory CRUD operations (create, update, delete)
- ✅ Supplier management with structured address fields and geographic coordinates
- ✅ Supplier CRUD operations (create, update)
- ✅ Production batch system (create, complete, fail)
- ✅ Recipe templates with ingredient ratios (independent of products)
- ✅ Recipe template CRUD operations (create, update, delete/soft delete)
- ✅ Purchase recording UI with supplier selection
- ✅ "What Can I Make?" feature for finished products
- ✅ Production history with yield tracking
- ✅ Adaptive navigation (mobile/desktop) with 4 tabs
- ✅ Platform-aware GraphQL client
- ✅ Stock consumption and production output tracking
- ✅ Automatic batch numbering
- ✅ Yield percentage calculation
- ✅ Database migrations system

### Next Steps / Planned Features

- [ ] Add map view for suppliers using `flutter_map` or `google_maps_flutter`
- [ ] Toggle between list/map view for suppliers
- [ ] Add filtering/sorting for inventory items and recipes
- [ ] Search functionality across all screens
- [ ] Detail screens for inventory items, suppliers, and production batches
- [ ] View production batch details (ingredients used, timeline, full history)
- [ ] Low stock notifications/badges
- [ ] Dark mode refinements
- [ ] Offline support with local caching
- [ ] Export data to CSV/Excel
- [ ] Analytics dashboard (stock trends, production yields, cost analysis)
- [ ] Barcode/QR code scanning for inventory
- [ ] Multi-user support with authentication
- [ ] Production reminders system (table exists, feature removed from app)

