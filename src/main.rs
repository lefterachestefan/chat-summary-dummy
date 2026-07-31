//! Stub binary that preserves the dependency graph for compile-time measurement.

#![allow(unused_imports)]

use actix_files as _;
use actix_multipart as _;
use actix_web as _;
use actix_ws as _;
use anyhow as _;
use axum as _;
use chrono as _;
use crawler as _;
use dotenvy as _;
use fastembed as _;
use futures as _;
use opentelemetry as _;
use opentelemetry_otlp as _;
use opentelemetry_sdk as _;
use qdrant_client as _;
use reqwest as _;
use serde as _;
use serde_json as _;
use thiserror as _;
use tokio as _;
use tracing as _;
use tracing_opentelemetry as _;
use tracing_subscriber as _;
use uuid as _;

fn main() {
    println!("c");
}
