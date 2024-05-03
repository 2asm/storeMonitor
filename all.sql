with t1 as (
    select distinct store_id 
    from (select store_id from store_timezone 
        union 
        select store_id from store_status 
        union 
        select store_id from menu_hours
    ) as t
), t2 as (
    select t1.*, coalesce(st.timezone_str, 'America/Chicago') as timezone_str 
    from t1 
    left join store_timezone as st 
    on t1.store_id=st.store_id
), t3 as (
    select  t2.store_id, t2.timezone_str,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day0 end as start_day0,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day1 end as start_day1,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day2 end as start_day2,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day3 end as start_day3,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day4 end as start_day4,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day5 end as start_day5,
    case when mh.store_id is NULL then '00:00:00' else mh.start_day6 end as start_day6,

    case when mh.store_id is NULL then '23:59:59' else mh.end_day0 end as end_day0,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day1 end as end_day1,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day2 end as end_day2,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day3 end as end_day3,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day4 end as end_day4,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day5 end as end_day5,
    case when mh.store_id is NULL then '23:59:59' else mh.end_day6 end as end_day6 
    from t2 
    left join menu_hours as mh 
    on t2.store_id=mh.store_id
), tx as (
    select ss.*, coalesce(st.timezone_str, 'America/Chicago') as timezone_str 
    from store_status as ss
    left join store_timezone as st 
    on ss.store_id=st.store_id
), ty as (
    select status_id, store_id, status, timestamp_utc,
    (timestamp_utc at time zone timezone_str)::time as tm,
    (extract(dow from timestamp_utc at time zone timezone_str)-1+7)%7 as wday
    from tx 
), t4 as (
    select store_id, 
        array_agg(status)::text[] as stats, 
        array_agg(timestamp_utc)::timestamptz[] as stamps,
        array_agg(tm)::time[] as tms,
        array_agg(wday)::int[] as days
    from ty 
    group by store_id
), t5 as (
    select t3.store_id,
        t3.start_day0, t3.start_day1, t3.start_day2, t3.start_day3, t3.start_day4, t3.start_day5, t3.start_day6,
        t3.end_day0, t3.end_day1, t3.end_day2, t3.end_day3, t3.end_day4, t3.end_day5, t3.end_day6, 
        t4.stats, t4.stamps, t4.tms, t4.days
    from t3 
    left join t4 
    on t3.store_id=t4.store_id
    group by t3.store_id,
        t3.start_day0, 
        t3.start_day1, 
        t3.start_day2, 
        t3.start_day3,
        t3.start_day4,
        t3.start_day5, 
        t3.start_day6,

        t3.end_day0,
        t3.end_day1,
        t3.end_day2,
        t3.end_day3,
        t3.end_day4,
        t3.end_day5,
        t3.end_day6, 
        t4.stats, t4.tms, t4.stamps, t4.days, t3.timezone_str
)
select * from t5;

