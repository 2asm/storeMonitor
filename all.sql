with t1 as (
    select distinct store_id 
    from (select distinct store_id from store_timezone 
        union 
        select distinct store_id from store_status 
        union 
        select distinct store_id from menu_hours
    ) as t
), t2 as (
    select  t1.store_id,
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
    from t1 
    left join menu_hours as mh 
    on t1.store_id=mh.store_id
), tx as (
    select ss.*, coalesce(st.timezone_str, 'America/Chicago') as timezone_str 
    from store_status as ss
    left join store_timezone as st 
    on ss.store_id=st.store_id
), ty as (
    select status_id, store_id, status, timestamp_utc,
    (timestamp_utc at time zone timezone_str)::time as local_time,
    (extract(dow from timestamp_utc at time zone timezone_str)-1+7)%7 as weekday
    from tx 
), t3 as (
    select store_id, 
        array_agg(status)::text[] as status_list, 
        array_agg(timestamp_utc)::timestamptz[] as timestamp_utc_list,
        array_agg(local_time)::time[] as local_time_list,
        array_agg(weekday)::int[] as weekday_list
    from ty 
    group by store_id
)

select t2.store_id,
    t2.start_day0, t2.start_day1, t2.start_day2, t2.start_day3, t2.start_day4, t2.start_day5, t2.start_day6,
    t2.end_day0, t2.end_day1, t2.end_day2, t2.end_day3, t2.end_day4, t2.end_day5, t2.end_day6, 
    t3.status_list, t3.timestamp_utc_list, t3.local_time_list, t3.weekday_list
from t2 
left join t3 
on t2.store_id=t3.store_id;

