import boto3
import gzip
import json
import base64
import os
from datetime import datetime, timedelta

# Set up clients
logs_client = boto3.client('logs')
log_group_name = os.environ['LOG_GROUP_NAME']
log_stream_name = os.environ['LOG_STREAM_NAME']

def lambda_handler(event, context):
    cw_data = event['awslogs']['data']
    compressed_payload = base64.b64decode(cw_data)
    uncompressed_payload = gzip.decompress(compressed_payload)
    
    payload = json.loads(uncompressed_payload)
    log_events = payload['logEvents']
    
    messages_to_log = []
    
    for log_event in log_events:
        log_message = json.loads(log_event["message"])
        if 'eventName' in log_message and log_message['eventName'] == 'ConsoleLogin':
            user = log_message['userIdentity']['userName']
            
            # Format the message without quotes around the USER key
            log_message_formatted = f'{{ USER: "{user} has logged in!" }}'
            
            # Convert event time from UTC string to timestamp
            event_time = datetime.strptime(log_message['eventTime'], '%Y-%m-%dT.%H:%M:%SZ')
            
            # Add 1 minute (60 seconds) to the timestamp
            event_time_with_offset = event_time + timedelta(minutes=1)
            
            # Convert the adjusted timestamp to milliseconds
            timestamp = int(event_time_with_offset.timestamp() * 1000)
            
            messages_to_log.append({
                'timestamp': timestamp,
                'message': log_message_formatted
            })

    if messages_to_log:
        # Send logs to CloudWatch Logs
        logs_client.put_log_events(
            logGroupName=log_group_name,
            logStreamName=log_stream_name,
            logEvents=messages_to_log
        )
