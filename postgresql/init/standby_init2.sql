\i '/docker-entrypoint-initdb.d/schema.sql'  -- Include the shared schema

-- Create subscription to the primary
DROP SUBSCRIPTION IF EXISTS my_subscription2;
CREATE SUBSCRIPTION my_subscription2
    CONNECTION 'host=pg_primary port=5432 dbname=primary_db user=rep_user password=rep_password'
    PUBLICATION my_publication
    WITH (connect = true, create_slot = false, enabled = true, slot_name = 'my_subscription2');