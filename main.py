import os
from threading import Thread
import psycopg
import uuid
from multiprocessing import Process, Pool
from queue import Queue

import csv
from datetime import timedelta, datetime
import time
from dateutil import tz

from flask import Flask, jsonify, send_from_directory
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

postgresUser = os.getenv("POSTGRES_USER")
postgresPassword = os.getenv("POSTGRES_PASSWORD")
postgresHost = os.getenv("POSTGRES_HOST")
postgresPort = os.getenv("POSTGRES_PORT")
postgresDB = os.getenv("POSTGRES_DB")

pool_size = os.getenv("POOLSIZE")
if pool_size:
    pool_size = int(pool_size)
else:
    pool_size = 4

print("Pool size:", pool_size)

dbInfo = f"host={postgresHost} port={postgresPort} user={postgresUser} \
        password={postgresPassword} dbname={postgresDB} sslmode=disable"

cur_time = datetime.now()
utc_zone = tz.gettz('UTC')
while True:
    try:
        with psycopg.connect(dbInfo) as conn:
            pass
        break
    except Exception:
        time.sleep(2)

with psycopg.connect(dbInfo) as conn:
    with conn.cursor() as cur:
        cur.execute("""TRUNCATE menu_hours;""")
        mp = dict()
        with open("data/menu_hours.csv") as fp:
            reader = csv.reader(fp, delimiter=",", quotechar='"')
            next(reader, None)  # skip the headers
            for row in reader:
                ind = int(row[1])
                if row[0] not in mp:
                    mp[row[0]] = [None]*14

                if mp[row[0]][ind] != None or mp[row[0]][ind+7] != None:
                    mp[row[0]][ind] = f"'00:00:00'"
                    mp[row[0]][7+ind] = f"'23:59:59'"
                else:
                    mp[row[0]][ind] = f"'{row[2]}'"
                    mp[row[0]][7+ind] = f"'{row[3]}'"

        for k,v in mp.items():
            for i in range(7):
                if mp[k][i] is None:
                    mp[k][i] = f"'00:00:00'"
                    mp[k][i+7] = f"'00:00:00'"

        for store_id, vals in mp.items():
            vals = [store_id] + vals
            cur.execute("""
                INSERT INTO menu_hours (
                    store_id,
                    start_day0, start_day1, start_day2, start_day3, start_day4, start_day5, start_day6,
                    end_day0, end_day1, end_day2, end_day3, end_day4, end_day5, end_day6
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
            """, vals)
        print("DB setup done")
        cur.execute("""select max(timestamp_utc) from store_status;""")
        e = cur.fetchone()
        if not e:
            raise Exception("Couldn't set current time")
        else:
            cur_time = e[0]

        print("Current time(UTC):", cur_time)
        conn.commit()


q = Queue()


@app.route('/')
def home():
    return jsonify({
        'msg': 'server online'
    })

def get_one(entry):
    uptime_last_hour = 60      # minutes
    uptime_last_day = 24       # hours
    uptime_last_week = 24*7    # hours

    downtime_last_hour = 0
    downtime_last_day = 0
    downtime_last_week = 0

    active_count_hour = 0
    inactive_count_hour = 0
    
    active_count_day = 0
    inactive_count_day = 0

    active_count_week = 0
    inactive_count_week = 0

    store_id = entry[0]
    if not entry[16]:
        return f"{store_id},{60},{24},{7*24},{0},{0},{0}\n"

    rs = entry[1:15]

    # to_zone = tz.gettz(entry[1])

    for status, t, lt, wday in zip(entry[15], entry[16], entry[17], entry[18]):
        # ltime = t.replace(tzinfo=utc_zone)
        # ltime = ltime.astimezone(to_zone)
        # wday = ltime.weekday()
        # lt = ltime.time()
        if lt>rs[wday] and lt<=rs[wday+7]:
            if cur_time - t <= timedelta(hours=1):
                if status == 'active':
                    active_count_week += 1
                    active_count_day += 1
                    active_count_hour += 1
                else:
                    inactive_count_week += 1
                    inactive_count_day += 1
                    inactive_count_hour += 1
            elif cur_time - t <= timedelta(days=1):
                if status == 'active':
                    active_count_day += 1
                    active_count_week += 1
                else:
                    inactive_count_day += 1
                    inactive_count_week += 1
            elif cur_time - t <= timedelta(days=7):
                if status == 'active':
                    active_count_week += 1
                else:
                    inactive_count_week += 1
    if active_count_week + inactive_count_week > 0:
        x = uptime_last_week
        uptime_last_week = int(x*(active_count_week)/(active_count_week + inactive_count_week))
        downtime_last_week = x - uptime_last_week
    if active_count_day + inactive_count_day > 0:
        x = uptime_last_day
        uptime_last_day = int(x*(active_count_day)/(active_count_day + inactive_count_day))
        downtime_last_day = x - uptime_last_day
    if active_count_hour + inactive_count_hour > 0:
        x = uptime_last_hour
        uptime_last_hour = int(x*(active_count_hour)/(active_count_hour + inactive_count_hour))
        downtime_last_hour = x - uptime_last_hour

    s = f"{store_id},{uptime_last_hour},{uptime_last_day},{uptime_last_week},{downtime_last_hour},{downtime_last_day},{downtime_last_week}\n"
    return s

def trigger_report_generation(report_id):
    xstart_time = time.time()
    tmp_file = f"reports/{report_id}-tmp.csv"
    final_file = f"reports/{report_id}.csv"
    with open(tmp_file, 'w') as f:
        f.write("store_id, uptime_last_hour, uptime_last_day, uptime_last_week, downtime_last_hour, downtime_last_day, downtime_last_week\n")

        with psycopg.connect(dbInfo) as conn:
            with conn.cursor() as cur:

                with open("all.sql", 'r') as f2:
                    cur.execute(f2.read())
                data = cur.fetchall()
                # print(data[0])

                i = 0
                for d in data: 
                    f.write(get_one(d))
                    if i>0 and i%1500 == 0:
                        print(f"Report - {report_id}.csv : {i/len(data)*100:.2f}% Done")
                    i += 1

            conn.commit()

    os.rename(tmp_file, final_file)
    xend_time = time.time()
    diff = int(xend_time-xstart_time)
    print(f"Report - {report_id}.csv : Complete in {diff} seconds")


def handle_all():
    with Pool(processes=pool_size) as pool:
        while True:
            id = q.get() 
            pool.apply_async(trigger_report_generation, args=(id,))


Thread(target=handle_all).start()

def handle_proc(p):
    p.join()

@app.route("/trigger_report")
def trigger_report():
    report_id = uuid.uuid4()
    # p = Process(target=trigger_report_generation, args=(report_id,))
    # p.start()
    # t = Thread(target=handle_proc, args=(p,))
    # t.start()
    q.put(report_id)
    return jsonify({
        'report_id': report_id
    })


@app.route("/get_report/<report_id>")
def get_report(report_id):
    try:
        uuid.UUID(report_id, version=4)
    except ValueError:
        return jsonify({
            'msg': 'invalid uuid',
        })

    if os.path.isfile(f"reports/{report_id}.csv"):
        return jsonify({
            'msg': 'Complete',
            'report': f"/reports/{report_id}.csv"
        })
    return jsonify({
        'msg': 'Running',
    })


@app.route('/reports/<report_name>')
def send_report(report_name):
    return send_from_directory('reports', report_name)
