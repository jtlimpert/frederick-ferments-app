mod models {
    pub mod inventory;
    pub mod production;
    pub mod sales;
    pub use inventory::*;
    pub use production::*;
    pub use sales::*;
}

mod resolvers {
    pub mod query;
    pub use query::*;
    pub mod mutation;
    pub use mutation::*;
}

use async_graphql::{EmptySubscription, Schema, http::GraphiQLSource};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};
use axum::{
    Router,
    extract::Extension,
    response::{self, IntoResponse},
    routing::get,
};
use resolvers::{MutationRoot, QueryRoot};
use sqlx::postgres::PgPoolOptions;
use tower_http::cors::CorsLayer;

type ApiSchema = Schema<QueryRoot, MutationRoot, EmptySubscription>;

async fn graphql_handler(schema: Extension<ApiSchema>, req: GraphQLRequest) -> GraphQLResponse {
    schema.execute(req.into_inner()).await.into()
}

async fn graphiql() -> impl IntoResponse {
    response::Html(GraphiQLSource::build().endpoint("/graphql").finish())
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    let database_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgresql://postgres:postgres@localhost:5432/frederick_ferments".to_string()
    });

    // Connect to database
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await?;

    // Create GraphQL schema
    let schema = Schema::build(QueryRoot, MutationRoot, EmptySubscription)
        .data(pool)
        .finish();

    // Build the app
    let app = Router::new()
        .route("/graphql", get(graphiql).post(graphql_handler))
        .layer(Extension(schema))
        .layer(CorsLayer::permissive());

    println!("🚀 GraphQL server running at http://localhost:4000/graphql");
    println!("📊 GraphiQL playground available at http://localhost:4000/graphql");

    let listener = tokio::net::TcpListener::bind("0.0.0.0:4000").await?;
    axum::serve(listener, app).await?;

    Ok(())
}
