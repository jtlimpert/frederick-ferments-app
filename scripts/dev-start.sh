#!/bin/bash
set -e

echo "🚀 Starting Frederick Ferments Development Environment..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Check if database is already running
if docker ps | grep -q frederick-ferments-db; then
    echo "✅ Database already running"
else
    echo "📦 Starting database..."
    docker-compose up db -d

    # Wait for database to be healthy
    echo "⏳ Waiting for database to be ready..."
    timeout=30
    elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if docker exec frederick-ferments-db pg_isready -U postgres > /dev/null 2>&1; then
            echo "✅ Database is ready!"
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    if [ $elapsed -ge $timeout ]; then
        echo "❌ Database failed to start within $timeout seconds"
        exit 1
    fi
fi

# Regenerate SQLx cache if needed
echo "🔄 Checking SQLx cache..."
cd backend
if cargo sqlx prepare --check > /dev/null 2>&1; then
    echo "✅ SQLx cache is up to date"
else
    echo "📝 Regenerating SQLx cache..."
    cargo sqlx prepare
    echo "✅ SQLx cache updated"
fi
cd ..

# Start the full stack
echo "🐳 Starting full stack with Docker..."
docker-compose up --build -d

# Wait for API to be healthy
echo "⏳ Waiting for API to be ready..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if curl -s http://localhost:4000/graphql -d '{"query":"query{ping}"}' -H "Content-Type: application/json" > /dev/null 2>&1; then
        echo "✅ API is ready!"
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

if [ $elapsed -ge $timeout ]; then
    echo "⚠️  API did not respond within $timeout seconds (but may still be starting)"
fi

echo ""
echo "✨ Development environment is ready!"
echo "   📊 GraphQL API: http://localhost:4000/graphql"
echo "   🗄️  Database: localhost:5433"
echo ""
echo "View logs: docker-compose logs -f"
echo "Stop all: docker-compose down"
