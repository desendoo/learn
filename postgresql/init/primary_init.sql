\i '/docker-entrypoint-initdb.d/schema.sql'  -- Include the shared schema

-- Create replication user
CREATE ROLE rep_user WITH REPLICATION LOGIN PASSWORD 'rep_password';

-- Insert initial data into the sample table
INSERT INTO sample_table (data) VALUES ('Hello, world!');

-- Create a publication for logical replication
DROP PUBLICATION IF EXISTS my_publication;
CREATE PUBLICATION my_publication FOR TABLE sample_table;

-- Enable extended display mode
\x

-- Create a logical replication slot for the subscription\
SELECT * FROM pg_create_logical_replication_slot('my_subscription', 'pgoutput');
SELECT * FROM pg_replication_slots;

-- Grant permissions to replication user
GRANT SELECT ON TABLE sample_table TO rep_user;