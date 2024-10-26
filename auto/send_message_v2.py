#!/usr/bin/env python3
import argparse
# import logging
import shlex
import subprocess
import sys
from botocore.session import Session
from pprint import pprint
from time import sleep


# Create CloudWatchLogs client
cloudwatch_logs = Session().create_client('logs')

# Define Argument Parser
parser = argparse.ArgumentParser(
    prog='send_message',
    description='Sends a message to your Lambda Producer\'s endpoint'
)

# Add arguments
parser.add_argument(
    "--name",
    help="Enter your name, e.g. John, Damian, Yussef",
    type=str)
parser.add_argument(
    "--superpower",
    help="Enter you superpower, e.g. flight, super-strength, observability",
    type=str)

# Get user arguments
args = parser.parse_args()
name = args.name
superpower = args.superpower


def get_url():
    return subprocess.run(
        shlex.split(
            "terraform output -raw base_url"),
        stdout=subprocess.PIPE,
        text=True
    ).stdout
  
def get_log_group_arn(service):
    lg_arn = [subprocess.run(
        shlex.split(
            f"terraform output -raw {service}_log_group_arn"),
        stdout=subprocess.PIPE,
        text=True
    ).stdout]
    
    return lg_arn

def start_live_tail(log_group_arn):
    # Get response object using Log Group ARN
    response = cloudwatch_logs.start_live_tail(logGroupIdentifiers=log_group_arn)

    # Get EventStream object from response
    event_stream = response['responseStream']

    # Get and print events from `sessionResults` list
    for event_group in event_stream:
        if 'sessionUpdate' in event_group.keys():
            if len(event_group['sessionUpdate']['sessionResults']) > 0:
                for event in event_group['sessionUpdate']['sessionResults']:
                    pprint(event)
                    print("\n\n")


if service in ['producer', 'consumer']:
    # Get Log Group ARN
    log_group_arn = get_log_group_arn(service)

    # Start Live Tail
    start_live_tail(log_group_arn)
else:
    pass

# Get URL for curl command, and defind curl command
curl_target = get_url()

# Define curl command
request = f"curl -d '{{ \"name\": \"{ name }\", \"superpower\": \"{ superpower }\" }}' { endpoint }"

count = 1000
while count > 0:
    count -= 1
    print(f"{ count } calls left")
    
    response = subprocess.run(
        shlex.split(request),
        stdout=subprocess.PIPE,
        text=True
    ).stdout
    print(response)

    sleep(1)
