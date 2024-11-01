#!/bin/bash

echo "===== BEGIN TEST ====="

# Function to set the PGPASSWORD environment variable
set_pgpassword() {
  export PGPASSWORD=$1
}

# Function to run a query on a specified database
run_query() {
  local host=$1
  local port=$2
  local user=$3
  local db=$4
  local query=$5
  psql -h $host -p $port -U $user -d $db -c "$query"
}

# Function to test data in a specified database
check_data() {
  local host=$1
  local port=$2
  local user=$3
  local db=$4
  echo "Data in $db:"
  run_query $host $port $user $db "SELECT * FROM sample_table;"
}

# Function to insert data into the database
insert_data_primary() {
  local host=$1
  local port=$2
  local user=$3
  local db=$4
  local query="INSERT INTO sample_table (data) VALUES ('Replication test ' || (SELECT COALESCE(MAX(id), 0) + 1 FROM sample_table));"
  run_query $host $port $user $db "$query"
}

# Function to check replication status
check_replication_status() {
  local host=$1
  local port=$2
  local user=$3
  local db=$4
  echo "Checking the subscription slot on ${host}..."
  psql -h $host -p $port -U $user -d $db -xc "SELECT * FROM pg_replication_slots"
  echo "Checking the replication status on ${host}..."
  psql -h $host -p $port -U $user -d $db -xc "SELECT * FROM pg_stat_replication"
}

# Function to check subscription status
check_subscription_status() {
  local host=$1
  local port=$2
  local user=$3
  local db=$4
  echo "Checking the subscription status on ${host}..."
  psql -h $host -p $port -U $user -d $db -xc "SELECT * FROM pg_subscription"
}

# Check the standby initially
echo "Checking standby..."
set_pgpassword $PG_STANDBY_PASSWORD
check_data $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB
echo "Checking standby2..."
export PG_STANDBY_HOST=postgresql-pg_standby2-1
check_data $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB

# Check the primary initially
echo "Checking primary..."
set_pgpassword $PG_PRIMARY_PASSWORD
check_data $PG_PRIMARY_HOST $PG_PRIMARY_DB_PORT $PG_PRIMARY_USER $PG_PRIMARY_DB

# Insert data into the primary to test replication
echo "Inserting data into primary..."
insert_data_primary $PG_PRIMARY_HOST $PG_PRIMARY_DB_PORT $PG_PRIMARY_USER $PG_PRIMARY_DB
insert_data_primary $PG_PRIMARY_HOST $PG_PRIMARY_DB_PORT $PG_PRIMARY_USER $PG_PRIMARY_DB

echo "Data in primary after insertion..."
check_data $PG_PRIMARY_HOST $PG_PRIMARY_DB_PORT $PG_PRIMARY_USER $PG_PRIMARY_DB

# Wait a moment for replication to take effect
sleep 1

# Check the standby again
set_pgpassword $PG_STANDBY_PASSWORD
echo "Data in standby after insertion from primary:"
export PG_STANDBY_HOST=postgresql-pg_standby-1
check_data $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB
echo "Data in standby2 after insertion from primary:"
export PG_STANDBY_HOST=postgresql-pg_standby2-1
check_data $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB

echo "Checking subscription status on standby..."
export PG_STANDBY_HOST=postgresql-pg_standby-1
check_subscription_status $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB
echo "Checking subscription status on standby2..."
export PG_STANDBY_HOST=postgresql-pg_standby2-1
check_subscription_status $PG_STANDBY_HOST $PG_STANDBY_DB_PORT $PG_STANDBY_USER $PG_STANDBY_DB

# Check replication status
set_pgpassword $PG_PRIMARY_PASSWORD
check_replication_status $PG_PRIMARY_HOST $PG_PRIMARY_DB_PORT $PG_PRIMARY_USER $PG_PRIMARY_DB

echo "===== END TEST ====="
