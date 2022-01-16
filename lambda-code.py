import boto3
from botocore.exceptions import ClientError
import os
import time
import json
import virustotal3.core
from os import listdir, system
import urllib.parse
import pg8000
import pymysql
import logging
import sys

API_KEY = os.environ["VT_API"]
DBENDPOINT = "DBENDPOINT"
DBNAME = "files"
DBUSER = "USER"
DBPASSWORD = "PASSWORD"

def lambda_handler(event, context):
    S3_BUCKET_NAME = event["Records"][0]["s3"]["bucket"]["name"]
    FILE_NAME = urllib.parse.unquote_plus(event["Records"][0]["s3"]["object"]["key"], encoding="utf-8")
    try:
        s3 = boto3.client("s3")
        s3.download_file(S3_BUCKET_NAME, FILE_NAME, "/tmp/{}".format(FILE_NAME))
    except ClientError as e:
        print("Unexpected error: %s" % e)
    print("file downloaded from Bucket")
    print(S3_BUCKET_NAME, FILE_NAME )

    vt = virustotal3.core.Files(API_KEY)
    response = vt.upload("/tmp/{}".format(FILE_NAME))
    print("file is being scanned")
    QUERY = "INSERT INTO files.status VALUES ('{}', 'scanning', 0, 0, 0);".format(FILE_NAME)
    print(QUERY)
    connection = connect_db()
    print("connected to DB")
    try:
        with connection.cursor() as cur:
            cur.execute(QUERY)
        connection.commit()
    except Exception as e:
        print("Failed due to :{0}".format(str(e)))
        return {"status": "Error", "message": "Something went wrong. Try again"}
    print("Added query {}".format(QUERY))

    analysis_id = response["data"]["id"]
    print("Analysis ID: {}".format(analysis_id))
    results = virustotal3.core.get_analysis(API_KEY, analysis_id)
    status = results["data"]["attributes"]["status"]

    print("Waiting for results...")
    while "completed" not in status:
        results = virustotal3.core.get_analysis(API_KEY, analysis_id)
        status = results["data"]["attributes"]["status"]
        print("Current status: {}".format(status))
        time.sleep(20)

    results = virustotal3.core.get_analysis(API_KEY, analysis_id)
    malicious = results["data"]["attributes"]["stats"]["malicious"]
    failure = results["data"]["attributes"]["stats"]["failure"]
    timeout = results["data"]["attributes"]["stats"]["timeout"]
    result_summary = """
    "malicious: ", {}
    "failure:   ", {}
    "timeout:   ", {}
    """.format(
        malicious, failure, timeout
    )
    print(result_summary)
    QUERY = "UPDATE files.status SET filemode = 'scanned',  malicious = {} , failure = {}, timeout = {} WHERE filename = '{}' ;".format(malicious, failure, timeout, FILE_NAME)
    try:
        with connection.cursor() as cur:
            cur.execute(QUERY)
        connection.commit()
    except Exception as e:
        print("Failed due to :{0}".format(str(e)))
        return {"status": "Error", "message": "Something went wrong. Try again"}
    print("Added query {}".format(QUERY))

def connect_db():
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    try:
        print("Connecting to database")
        RDS_client = boto3.client("rds", region_name="us-east-1")
        PASSWORD = RDS_client.generate_db_auth_token(DBENDPOINT, 3306, DBUSER)
        print(PASSWORD)
        conn = pymysql.connect(
            host=DBENDPOINT,
            user=DBUSER,
            passwd=DBPASSWORD,
            db=DBNAME,
        )
        return conn
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        sys.exit()
