DROP TABLE IF EXISTS store_status;
CREATE TABLE store_status (
    status_id serial PRIMARY KEY,
    store_id bigint NOT NULL,
    status varchar(20) NOT NULL,
    timestamp_utc timestamptz NOT NULL
);

DROP TABLE IF EXISTS menu_hours;
CREATE TABLE menu_hours(
    store_id bigint PRIMARY KEY,

    start_day0 time,
    end_day0 time,

    start_day1 time,
    end_day1 time,

    start_day2 time,
    end_day2 time,

    start_day3 time,
    end_day3 time,

    start_day4 time,
    end_day4 time,

    start_day5 time,
    end_day5 time,

    start_day6 time,
    end_day6 time
);

DROP TABLE IF EXISTS store_timezone;
CREATE TABLE store_timezone (
    store_id bigint PRIMARY KEY,
    timezone_str varchar(100) NOT NULL
);

