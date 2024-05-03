#!/bin/sh

cat data/segment_aa data/segment_ab > data/store_status.csv

psql -U postgres \
    -d postgres \
    -f /docker-entrypoint-initdb.d/setup.sql

echo -n > /docker-entrypoint-initdb.d/setup.sql

psql -U postgres \
    -d postgres \
    -c "COPY store_timezone(store_id, timezone_str) FROM '/data/store_timezone.csv' DELIMITER ',' CSV HEADER;"

psql -U postgres \
    -d postgres \
    -c "COPY store_status(store_id, status, timestamp_utc) FROM '/data/store_status.csv' DELIMITER ',' CSV HEADER;"
