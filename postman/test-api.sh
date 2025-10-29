#!/bin/bash
# Quick API testing script for Frederick Ferments
# Usage: ./test-api.sh [command]

API_URL="http://localhost:4000/graphql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
}

function test_ping() {
    print_header "Testing API Connectivity (Ping)"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{ping}"}')

    if echo "$response" | jq -e '.data.ping == "pong"' > /dev/null; then
        print_success "API is responding"
        echo "$response" | jq '.'
    else
        print_error "API ping failed"
        echo "$response"
    fi
}

function test_health() {
    print_header "Checking API Health"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{healthCheck{status timestamp databaseConnected version uptimeSeconds}}"}')

    if echo "$response" | jq -e '.data.healthCheck.status == "healthy"' > /dev/null; then
        print_success "API is healthy"
        echo "$response" | jq '.data.healthCheck'
    else
        print_error "Health check failed"
        echo "$response"
    fi
}

function test_inventory() {
    print_header "Fetching Inventory Items"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{inventoryItems{id name category currentStock unit}}"}')

    count=$(echo "$response" | jq '.data.inventoryItems | length')
    print_success "Found $count inventory items"
    echo "$response" | jq '.data.inventoryItems'
}

function test_suppliers() {
    print_header "Fetching Suppliers"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{suppliers{id name city state}}"}')

    count=$(echo "$response" | jq '.data.suppliers | length')
    print_success "Found $count suppliers"
    echo "$response" | jq '.data.suppliers'
}

function test_batches() {
    print_header "Fetching Active Production Batches"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{activeBatches{id batchNumber status startDate}}"}')

    count=$(echo "$response" | jq '.data.activeBatches | length')
    print_success "Found $count active batches"
    echo "$response" | jq '.data.activeBatches'
}

function test_recipes() {
    print_header "Fetching Recipe Templates"
    response=$(curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d '{"query":"query{recipeTemplates{id templateName description}}"}')

    count=$(echo "$response" | jq '.data.recipeTemplates | length')
    print_success "Found $count recipe templates"
    echo "$response" | jq '.data.recipeTemplates'
}

function run_all_tests() {
    test_ping
    echo ""
    test_health
    echo ""
    test_inventory
    echo ""
    test_suppliers
    echo ""
    test_batches
    echo ""
    test_recipes
}

function show_help() {
    cat << EOF
Frederick Ferments API Test Script

Usage: $0 [command]

Commands:
  ping       - Test API connectivity
  health     - Check API health status
  inventory  - List inventory items
  suppliers  - List suppliers
  batches    - List active production batches
  recipes    - List recipe templates
  all        - Run all tests
  help       - Show this help message

Examples:
  $0 ping
  $0 health
  $0 all

EOF
}

# Main execution
case "${1:-all}" in
    ping)
        test_ping
        ;;
    health)
        test_health
        ;;
    inventory)
        test_inventory
        ;;
    suppliers)
        test_suppliers
        ;;
    batches)
        test_batches
        ;;
    recipes)
        test_recipes
        ;;
    all)
        run_all_tests
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
