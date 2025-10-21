# Frederick Ferments

A comprehensive inventory management system designed for fermentation businesses, built with Rust, GraphQL, PostgreSQL, and Flutter.

## Overview

Frederick Ferments is a full-stack application that helps fermentation businesses manage their operations, from ingredient inventory and supplier relationships to production batches and recipe templates. The system provides real-time stock tracking, production yield monitoring, and structured recipe management with ingredient ratios.

### Key Features

#### Inventory Management
- **Real-time Stock Tracking**: Monitor current stock, reserved stock, and available stock levels
- **Stock Status Indicators**: Color-coded visual alerts for healthy, low, and critical stock levels
- **Reorder Points**: Automatic low-stock detection based on configurable thresholds
- **Full CRUD Operations**: Create, update, and delete inventory items
- **Cost Tracking**: Per-unit cost tracking with automatic updates on purchases
- **Supplier Integration**: Link inventory items to preferred suppliers

#### Production Batch Management
- **Batch Tracking**: Complete lifecycle tracking from start to completion or failure
- **Recipe Templates**: Reusable templates with ingredient ratios and instructions
- **Yield Monitoring**: Automatic calculation of production time and yield percentages
- **Stock Reservation**: Ingredients automatically reserved when batches start
- **"What Can I Make?"**: Intelligent feature showing producible items based on current stock
- **Production History**: Complete audit trail with status, yields, and quality notes

#### Recipe Templates
- **Independent Recipes**: Support for recipes not linked to specific products (experimental/intermediate)
- **Ingredient Ratios**: JSONB-based ingredient templates with quantities per batch
- **Batch Scaling**: Default batch sizes with flexible scaling
- **Estimated Duration**: Track and improve production time estimates
- **Full CRUD Operations**: Create, update, and soft-delete recipe templates

#### Supplier Management
- **Structured Address Fields**: Street, city, state, zip code, and country
- **Geographic Coordinates**: Latitude/longitude support for map visualization (planned)
- **Contact Information**: Email, phone, and notes
- **Full CRUD Operations**: Create and update supplier information

#### Purchase Recording
- **Multi-Item Purchases**: Record purchases with multiple items in a single transaction
- **Batch Tracking**: Optional batch numbers and expiry dates
- **Cost History**: Maintains complete purchase history in inventory logs
- **Automatic Stock Updates**: Stock levels updated atomically with purchases

#### Cross-Platform UI
- **Adaptive Navigation**: Bottom navigation (mobile) or side rail (web/desktop)
- **Material 3 Design**: Modern, consistent design language across all screens
- **Platform-Aware**: Automatically configures API endpoints for Android, iOS, web, macOS
- **Responsive**: Optimized layouts for phones, tablets, and desktop browsers
- **Pull-to-Refresh**: Real-time data updates across all screens

## Tech Stack

### Backend
- **Language**: Rust 1.75+
- **API Framework**: Axum 0.8.4
- **GraphQL**: async-graphql 7.0.17
- **Database**: PostgreSQL 16 with SQLx for type-safe queries
- **Runtime**: Tokio async runtime
- **Deployment**: Docker Compose with health checks

### Frontend
- **Framework**: Flutter (Dart SDK 3.9.2+)
- **State Management**: Riverpod
- **GraphQL Client**: graphql_flutter
- **Platforms**: iOS, Android, Web, macOS, Windows, Linux

### Database
- **RDBMS**: PostgreSQL 16
- **Migrations**: SQL migration files in `migrations/` directory
- **Query Safety**: SQLx compile-time verified queries
- **Type Safety**: BigDecimal for precise decimal arithmetic

## Quick Start

### Prerequisites
- Docker and Docker Compose
- (Optional) Flutter SDK for frontend development
- (Optional) Rust toolchain for backend development

### Using Docker (Recommended)

The fastest way to get started is using the provided development script:

```bash
# Make the script executable (first time only)
chmod +x scripts/dev-start.sh

# Start the full stack
./scripts/dev-start.sh
```

This script automatically:
1. Starts PostgreSQL database
2. Waits for database to be healthy
3. Regenerates SQLx cache if needed
4. Builds and starts the API server
5. Waits for API to be ready

**Or use VSCode tasks:**
- Press `Cmd+Shift+P` → "Tasks: Run Task" → "🚀 Start Full Dev Environment"
- Or press `Cmd+Shift+B` (default build task)

### Manual Docker Setup

```bash
# Start the full stack
docker-compose up

# Or start just the database
docker-compose up db
```

### Access Points

Once running, you can access:
- **GraphQL Playground**: http://localhost:4000/graphql (interactive API explorer)
- **GraphQL API**: http://localhost:4000/graphql (POST requests)
- **PostgreSQL**: localhost:5432 (username: postgres, password: postgres, database: frederick_ferments)

## Development Setup

### Backend Development

```bash
cd backend

# Install dependencies (first time)
cargo build

# Run locally (requires PostgreSQL running)
cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Lint code
cargo clippy

# Update SQLx cache (after SQL changes)
cargo sqlx prepare
```

**About SQLx Offline Mode:**
The backend uses `SQLX_OFFLINE=true` for Docker builds. Query metadata is cached in `backend/.sqlx/`. Update the cache whenever you:
- Change SQL queries in the code
- Modify database schema
- Add/remove database columns

### Frontend Development

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on auto-selected device
flutter run

# Run on specific platform
flutter run -d chrome         # Web browser
flutter run -d macos          # macOS desktop
flutter run -d ios            # iOS Simulator
flutter run -d android        # Android Emulator

# Generate code (after model changes)
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Clean build artifacts
flutter clean
```

### Database Management

```bash
# Connect to database
docker exec -it frederick-ferments-db psql -U postgres -d frederick_ferments

# Reset database (WARNING: destroys all data)
docker-compose down -v

# View database logs
docker-compose logs db

# Run SQL migration
docker exec -i frederick-ferments-db psql -U postgres -d frederick_ferments < migrations/001_make_recipe_product_optional.sql
```

## Project Structure

```
frederick-ferments-app/
├── backend/                    # Rust GraphQL API
│   ├── src/
│   │   ├── main.rs            # Server entry point
│   │   ├── models/
│   │   │   ├── inventory.rs   # Inventory & Supplier models
│   │   │   └── production.rs  # Production & Recipe models
│   │   └── resolvers/
│   │       ├── query.rs       # GraphQL queries (253 lines)
│   │       └── mutation.rs    # GraphQL mutations (1,168 lines)
│   ├── .sqlx/                 # SQLx offline query cache
│   ├── Cargo.toml             # Rust dependencies
│   └── Dockerfile             # Production container
├── frontend/                   # Flutter cross-platform app
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── screens/           # 12+ UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── inventory_list_screen.dart
│   │   │   ├── production_screen.dart
│   │   │   ├── recipes_screen.dart
│   │   │   └── suppliers_screen.dart
│   │   ├── models/            # Data models
│   │   ├── services/          # GraphQL service layer
│   │   └── widgets/           # Reusable UI components
│   └── pubspec.yaml           # Flutter dependencies
├── migrations/                 # Database migrations
│   └── 001_make_recipe_product_optional.sql
├── scripts/
│   └── dev-start.sh           # Automated development startup
├── docker-compose.yml         # Multi-container orchestration
├── init.sql                   # Database schema & seed data
├── CLAUDE.md                  # Developer documentation (detailed)
└── README.md                  # This file
```

## GraphQL API

### Example Queries

**Get all inventory items:**
```graphql
query {
  inventoryItems {
    id
    name
    category
    currentStock
    availableStock
    reorderPoint
  }
}
```

**Get active production batches:**
```graphql
query {
  activeBatches {
    id
    batchNumber
    productInventoryId
    batchSize
    status
    startDate
  }
}
```

**Get recipe templates:**
```graphql
query {
  recipeTemplates {
    id
    templateName
    productInventoryId
    defaultBatchSize
    ingredientTemplate
    instructions
  }
}
```

### Example Mutations

**Create inventory item:**
```graphql
mutation {
  createInventoryItem(input: {
    name: "Organic Wheat Flour"
    category: "ingredient"
    unit: "kg"
    reorderPoint: 10.0
  }) {
    success
    message
    item { id name }
  }
}
```

**Record a purchase:**
```graphql
mutation {
  createPurchase(input: {
    supplierId: "uuid-here"
    items: [
      { inventoryId: "uuid-here", quantity: "50", unitCost: "2.75" }
    ]
  }) {
    success
    updatedItems { name currentStock }
  }
}
```

**Create production batch:**
```graphql
mutation {
  createProductionBatch(input: {
    productInventoryId: "uuid-here"
    recipeTemplateId: "uuid-here"
    batchSize: 2.0
    unit: "loaves"
    ingredients: [
      { inventoryId: "flour-id", quantityUsed: 1.0 }
    ]
  }) {
    success
    batchNumber
  }
}
```

For complete API documentation, see [CLAUDE.md](CLAUDE.md#graphql-api).

## Database Schema

The system uses 6 main tables:

1. **suppliers** - Supplier information with structured addresses and coordinates
2. **inventory** - Inventory items with stock levels, reorder points, and costs
3. **inventory_logs** - Complete audit trail of all stock movements
4. **recipe_templates** - Reusable recipes with ingredient ratios (optional product link)
5. **production_batches** - Production batch tracking with yields and status
6. **production_batch_ingredients** - Ingredients used in each batch

All tables use UUIDs for primary keys and include automatic timestamp management.

## Features Roadmap

### Completed ✅
- ✅ Inventory CRUD with stock indicators
- ✅ Supplier CRUD with structured addresses
- ✅ Production batch lifecycle management
- ✅ Recipe templates (independent of products)
- ✅ Purchase recording
- ✅ "What Can I Make?" feature
- ✅ Adaptive navigation (4 tabs)
- ✅ Cross-platform Flutter app
- ✅ GraphQL API with full CRUD
- ✅ Database migrations system

### Planned 🚧
- Map view for suppliers with pins
- Filtering and search across all screens
- Detail screens with full history
- Low stock notifications/badges
- Analytics dashboard
- Data export (CSV/Excel)
- Barcode scanning
- Multi-user authentication
- Offline support

## Contributing

This is a private project for Frederick Ferments. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Quality

- **Backend**: Run `cargo fmt` and `cargo clippy` before committing
- **Frontend**: Run `dart format` and `dart analyze` before committing
- **Tests**: Ensure all tests pass with `cargo test` and `flutter test`

## Environment Variables

### Backend (.env)

```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/frederick_ferments
RUST_LOG=info
```

### Frontend

No environment variables required. API endpoints are automatically configured based on platform.

## License

This project is proprietary software for Frederick Ferments.

## Support

For issues, questions, or feature requests, please contact the development team.

---

**Built with ❤️ for Frederick Ferments**
