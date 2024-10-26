#!/usr/bin/env python3
import argparse
import shlex
import subprocess
import sys
# from botocore.session import Session


# Create CloudWatchLogs client
cloudwatch_logs = Session().create_client('logs')

parser = argparse.ArgumentParser(
    prog='get_logs',
    description='Does a live tail of either your Producer or Consumer function'
)

parser.add_argument(
    "--function",
    help="Choose between the producer or consumer logs",
    choices=['producer', 'consumer'],
    type=str
)

function_type = parser.parse_args()

if function_type.function in ['producer', 'consumer']:
    """
    # Get Log Group ARN
    log_group_arn = [subprocess.run(
        shlex.split(
            f"terraform output -raw {function_type.function}_log_group_arn"),
        stdout=subprocess.PIPE,
        text=True
    ).stdout]

    # Start Live Tail
    response = cloudwatch_logs.start_live_tail(logGroupIdentifiers=log_group_arn)
    event_stream = response['responseStream']
    for event in event_stream:
        print(event)
    """

    # Get Log Group Name
    log_group_name = subprocess.run(
        shlex.split(
            f"terraform output -raw {function_type.function}_log_group_name"),
        stdout=subprocess.PIPE,
        text=True
    ).stdout
    
    live_tail_command = f"aws logs tail --log-group-identifiers {log_group_name}"

    with open(f"{function_type.function}.log", "wb") as f:
        process = subprocess.run(shlex.split(live_tail_command), stdout=subprocess.PIPE)
        for line in iter(process.stdout.readline, b""):
            sys.stdout.write(line)
            f.write(line)
else:
    pass
