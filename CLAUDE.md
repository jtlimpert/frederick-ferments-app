# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

Frederick Ferments is a fermentation business inventory management system built with:

- **Backend**: Rust GraphQL API using async-graphql (v7.0.17) and Axum (v0.8.4)
- **Database**: PostgreSQL 16 with SQLx for type-safe queries
- **Deployment**: Docker Compose setup with health checks
- **Runtime**: Tokio async runtime

The system tracks inventory items with fields for stock levels, reorder points, suppliers, and purchase history. The GraphQL API provides queries for inventory items and suppliers, with mutations for purchase operations.

### Key Components

**Backend Structure:**
- `backend/src/main.rs`: Main server entry point with GraphQL schema setup and connection pooling (max 10 connections)
- `backend/src/models/inventory.rs`: Core data models (InventoryItem, Supplier, Purchase inputs/outputs)
- `backend/src/resolvers/query.rs`: GraphQL query resolvers (inventory_items, suppliers, health_check, ping)
- `backend/src/resolvers/mutation.rs`: GraphQL mutation resolvers (create_purchase)
- `backend/Cargo.toml`: Dependencies configuration

**Infrastructure:**
- `docker-compose.yml`: Complete deployment stack with PostgreSQL and API containers
- `init.sql`: Database schema initialization with sample data

### Database Schema

**Tables:**

1. **suppliers** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `name`: VARCHAR (NOT NULL)
   - `contact_email`, `contact_phone`, `address`, `notes`: Optional fields
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

3. **inventory_log** (UUID primary key)
   - `id`: UUID (auto-generated)
   - `inventory_id`: UUID (foreign key to inventory, NOT NULL)
   - `movement_type`: VARCHAR (NOT NULL) - values: 'purchase', 'sale', 'adjustment', 'waste'
   - `quantity`: DECIMAL (NOT NULL)
   - `unit_cost`: DECIMAL (nullable)
   - `reason`: TEXT (nullable)
   - `batch_number`: VARCHAR (nullable)
   - `expiry_date`: DATE (nullable)
   - `created_at`: TIMESTAMPTZ (auto-managed)

**Indexes:**
- `idx_inventory_active` on inventory(is_active)
- `idx_inventory_category` on inventory(category)
- `idx_inventory_supplier` on inventory(default_supplier_id)
- `idx_inventory_log_item` on inventory_log(inventory_id)
- `idx_inventory_log_date` on inventory_log(created_at)

## Development Commands

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
    pub address: Option<String>,
    pub notes: Option<String>,
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

**4. Get All Suppliers** (`backend/src/resolvers/query.rs:86`)
```graphql
query {
  suppliers {
    id
    name
    contactEmail
    contactPhone
    address
    notes
    createdAt
    updatedAt
  }
}
```
- Ordered by name alphabetically

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

**Purchase Flow** (`backend/src/resolvers/mutation.rs:13-92`):
1. Begins database transaction
2. For each item in purchase:
   - Inserts entry into `inventory_log` table with movement_type='purchase'
   - Updates `inventory` table: increments `current_stock`, updates `cost_per_unit`
3. Commits transaction (atomic - all succeed or all fail)
4. Returns success status and updated inventory items

**Key Behaviors:**
- All operations are transactional (rollback on any error)
- Stock updates are additive: `current_stock = current_stock + quantity`
- Cost is updated to the most recent purchase price
- Audit trail maintained in `inventory_log`

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
All inventory movements are logged in `inventory_log` table with movement_type, quantity, cost, and timestamps.

### Error Handling
- GraphQL resolvers return `async_graphql::Result` type
- Database errors propagate as GraphQL errors
- Transactions ensure atomic operations (all-or-nothing)