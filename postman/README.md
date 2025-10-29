# Frederick Ferments API - Postman Collection

This directory contains Postman collection and environment files for testing the Frederick Ferments GraphQL API.

## Files

- **Frederick_Ferments_API.postman_collection.json** - Complete API collection with all queries and mutations
- **Frederick_Ferments_Environment.postman_environment.json** - Environment variables for local development

## Quick Start

### 1. Import into Postman

**Import Collection:**
1. Open Postman
2. Click "Import" button (top left)
3. Select `Frederick_Ferments_API.postman_collection.json`
4. Click "Import"

**Import Environment:**
1. Click "Import" button again
2. Select `Frederick_Ferments_Environment.postman_environment.json`
3. Click "Import"

### 2. Activate Environment

1. In Postman, look for the environment dropdown (top right)
2. Select "Frederick Ferments - Local"
3. The environment is now active

### 3. Start Using the API

The collection is organized into folders:

- **Health & Status** - Quick health checks and ping
- **Queries** - Read operations (inventory, suppliers, production, recipes)
- **Mutations** - Write operations organized by domain:
  - Inventory Management
  - Supplier Management
  - Purchase Management
  - Production Management
  - Recipe Management
- **Example Workflows** - Multi-step process examples

## Environment Variables

The environment includes these variables:

| Variable | Default Value | Description |
|----------|--------------|-------------|
| `api_url` | `http://localhost:4000/graphql` | GraphQL API endpoint |
| `db_host` | `localhost` | Database host |
| `db_port` | `5433` | Database port (mapped from 5432) |
| `inventory_item_id` | (empty) | Store inventory item IDs here |
| `supplier_id` | (empty) | Store supplier IDs here |
| `batch_id` | (empty) | Store production batch IDs here |
| `recipe_template_id` | (empty) | Store recipe template IDs here |

### Using Variables

Many mutations use environment variables like `{{inventory_item_id}}`. To use them:

1. Run a create mutation (e.g., Create Inventory Item)
2. Copy the `id` from the response
3. Click the environment name (top right) → "Edit"
4. Paste the ID into the appropriate variable
5. Save the environment

Now other requests can reference this ID using `{{inventory_item_id}}`.

## Example Workflow

Here's a typical workflow for creating a production batch:

### 1. Create Ingredients
```graphql
# Create flour ingredient
mutation {
  createInventoryItem(input: {
    name: "Whole Wheat Flour"
    category: "ingredient"
    unit: "kg"
    reorderPoint: 10.0
    costPerUnit: 2.50
  }) {
    success
    item { id }  # Save this ID as inventory_item_id
  }
}
```

### 2. Create Supplier
```graphql
mutation {
  createSupplier(input: {
    name: "Local Grain Mill"
    contactEmail: "orders@grainmill.com"
    city: "Frederick"
    state: "MD"
  }) {
    success
    supplier { id }  # Save this ID as supplier_id
  }
}
```

### 3. Record Purchase
```graphql
mutation {
  createPurchase(input: {
    supplierId: "{{supplier_id}}"
    items: [
      {
        inventoryId: "{{inventory_item_id}}"
        quantity: 50.0
        unitCost: 2.50
      }
    ]
  }) {
    success
    updatedItems {
      name
      currentStock
    }
  }
}
```

### 4. Create Finished Product
```graphql
mutation {
  createInventoryItem(input: {
    name: "Sourdough Bread"
    category: "finished_product"
    unit: "loaves"
    reorderPoint: 5.0
  }) {
    success
    item { id }  # Use this as productInventoryId
  }
}
```

### 5. Create Recipe Template
```graphql
mutation {
  createRecipeTemplate(input: {
    productInventoryId: "{{inventory_item_id}}"
    templateName: "Classic Sourdough"
    defaultBatchSize: 2.0
    defaultUnit: "loaves"
    estimatedDurationHours: 24.0
  }) {
    success
    recipeTemplate { id }  # Save as recipe_template_id
  }
}
```

### 6. Start Production Batch
```graphql
mutation {
  createProductionBatch(input: {
    productInventoryId: "{{inventory_item_id}}"
    recipeTemplateId: "{{recipe_template_id}}"
    batchSize: 2.0
    unit: "loaves"
    ingredients: [
      {
        inventoryId: "{{inventory_item_id}}"
        quantityUsed: 1.0
      }
    ]
  }) {
    success
    batchId  # Save as batch_id
    batchNumber
  }
}
```

### 7. Complete Production Batch
```graphql
mutation {
  completeProductionBatch(input: {
    batchId: "{{batch_id}}"
    actualYield: 1.9
    qualityNotes: "Perfect rise!"
  }) {
    success
    message
  }
}
```

## GraphQL Tips

### Variables in Postman

Postman supports GraphQL natively. When editing a request:

1. Switch body mode to "GraphQL"
2. Write your query in the "Query" section
3. Define variables in the "GraphQL Variables" section (JSON format)
4. Postman will automatically send the correct GraphQL request

### Testing Queries

Start with simple queries to verify connectivity:

```graphql
query {
  ping
}
```

Then try the health check:

```graphql
query {
  healthCheck {
    status
    databaseConnected
  }
}
```

### Error Handling

GraphQL returns errors in a specific format:

```json
{
  "errors": [
    {
      "message": "Error description",
      "locations": [...],
      "path": [...]
    }
  ]
}
```

Check the `errors` array in responses for detailed error information.

## API Documentation

For complete API documentation, see:
- **CLAUDE.md** - Detailed technical documentation
- **README.md** - Project overview and setup

## Common Operations

### Check Stock Levels
Use the "Get All Inventory Items" query and look at:
- `currentStock` - Total physical stock
- `reservedStock` - Stock allocated to in-progress batches
- `availableStock` - Stock available for use (currentStock - reservedStock)

### View Production Status
- **Active batches**: "Get Active Batches" query
- **History**: "Get Production History" query (filter by product or limit)

### Recipe Management
- List all recipes: "Get Recipe Templates"
- Recipes can exist without a linked product (for experimental recipes)
- `ingredientTemplate` is stored as JSONB with ingredient ratios

## Troubleshooting

### Connection Issues

If requests fail with connection errors:

1. Verify the API is running:
   ```bash
   docker compose ps
   ```

2. Check the API is responding:
   ```bash
   curl http://localhost:4000/graphql -d '{"query":"query{ping}"}'
   ```

3. Verify environment variables:
   - Check `api_url` is set correctly
   - Make sure environment is activated (top right dropdown)

### UUID Issues

If you get "invalid UUID" errors:
- UUIDs must be in format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- Get valid UUIDs from create operations or query responses
- Store them in environment variables for reuse

### Database Port

Note: The database is exposed on port **5433** (not 5432) to avoid conflicts with local PostgreSQL instances.

## Support

For issues or questions:
- Check the main README.md for project setup
- Review CLAUDE.md for detailed API documentation
- Ensure Docker containers are running: `docker compose ps`
