# Store monitor
### System Info
- Ubuntu 22.04 LTS
- Docker
### Tech Stack
- Flask
- Postgresql
### HOW TO RUN
```Console
$ git clone https://github.com/2asm/storeMonitor.git
$ cd storeMonitor
$ docker-compose up --build -V
```
make sure port 5000 and 5432(postgres) are not in use on your machine, to stop postgres run this command
```Console
$ sudo systemctl stop postgresql
```
Service will run on locahost: 127.0.0.1:5000
### Apis with dummy response
http://127.0.0.1:5000   (home page to check server status) <br>
```
{
  "msg":"server online"
}
```
http://127.0.0.1:5000/trigger_report <br>
```
{
  "report_id":"67998f3d-6253-4e11-a687-67a176dc944a"
}
```
http://127.0.0.1:5000/get_report/<report_id>
```
// when report is being generated
{
  "msg":"Running"
}
```
```
// when report is ready to access
{
  "msg":"Complete",
  "report":"/reports/67998f3d-6253-4e11-a687-67a176dc944a.csv"
}
```
I'm currently using uuid as report name but in live system we can use combination of current time, node_id and local increment 
### Stats on my laptop (for process pool of size 4)
- Average report generation time for single request = 20 seconds
- Average report generation time for 10 concurrent request = 40 seconds <br>
You can update process POOLSIZE in .env file (do not update anything else, it could break 'docker-compose up')
# Logic
Take all the timestamps in business hours <br>
Count all ative and inactive status <br>
Now uptime = (active count)/(active + inactive count) * total_time <br>
downtime = (inactive count)/(active + inactive count) * total_time <br>
total_time => week, day or hour
```
# Pseudocode
cur_time = max_time_in_store_status_table
def generate_report_week(store_id): # for single store
    stamps = get_all_the_timestamp_and_status(store_id) # downtime = 0 if no observations
    working_hours = get_business_hours_for(store_id) # for all 7 days
    active_count = 0
    inactive_count = 0
    for timestamp, status in stamps:
        if cur_time-timestamp>= week:
            continue
        local_timestamp = convert_to_local_with_timezone(timestamp)
        local_time = local_timestamp.time()
        wday = local_timestamp.weekday() # local weekday
        if local_time in working_hours: # localtime>=working_hours[wday].start_time and localtime<=working_hours[wday].end_time
            if status is active:
                active_count += 1
            else:
                inactive_count += 1
    uptime = active_count/(active_count+inactive_count)*24*7 # hours
    downtime = inactive_count/(active_count+inactive_count)*24*7 # hours
        
```
similarly for day and hour
### TODO
More Testing( did some manual testing on few stores )
