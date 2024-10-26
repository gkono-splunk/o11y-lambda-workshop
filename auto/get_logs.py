#!/usr/bin/env python3
import argparse
# import logging
import shlex
import subprocess
import sys
from botocore.session import Session
from pprint import pprint


# Create CloudWatchLogs client
cloudwatch_logs = Session().create_client('logs')

# Define Argument Parser
parser = argparse.ArgumentParser(
    prog='get_logs',
    description='Does a live tail of either your Producer or Consumer service'
)

# Add argument and choices
parser.add_argument(
    "--service",
    help="Choose between the producer or consumer logs",
    choices=['producer', 'consumer'],
    type=str
)

# Get value from parser arguments
service = parser.parse_args().service

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
