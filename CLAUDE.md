# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

Frederick Ferments is a fermentation business inventory management system built with:

- **Backend**: Rust GraphQL API using async-graphql and Axum
- **Database**: PostgreSQL with inventory and supplier tables
- **Deployment**: Docker Compose setup with health checks

The system tracks inventory items with fields for stock levels, reorder points, suppliers, and purchase history. The GraphQL API provides queries for inventory items and suppliers, with mutations for purchase operations.

### Key Components

- `backend/src/main.rs`: Main server entry point with GraphQL schema setup
- `backend/src/models/inventory.rs`: Core data models (InventoryItem, Supplier, Purchase inputs)
- `backend/src/resolvers/query.rs`: GraphQL query resolvers for inventory and suppliers
- `backend/src/resolvers/mutation.rs`: GraphQL mutation resolvers for purchase operations
- `docker-compose.yml`: Complete deployment stack with PostgreSQL and API containers

### Database Schema

The system uses PostgreSQL with tables for inventory tracking:
- Inventory items with current/reserved/available stock calculations
- Supplier management with contact information
- Purchase tracking with batch numbers and expiry dates

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
- GraphQL endpoint: `http://localhost:4000/graphql`
- GraphiQL playground: `http://localhost:4000/graphql` (browser)

Key queries and mutations available through the schema include inventory management, supplier tracking, and purchase operations.

## Environment Configuration

The backend uses these environment variables:
- `DATABASE_URL`: PostgreSQL connection string (defaults to local Docker setup)
- `RUST_LOG`: Logging level (set to `info` in Docker)
- `PORT`: API server port (defaults to 4000)

Environment variables can be set in `backend/.env` for local development.