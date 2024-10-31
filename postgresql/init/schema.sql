-- Define the schema for sample_table
CREATE TABLE IF NOT EXISTS sample_table (
    id SERIAL PRIMARY KEY,
    data TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);