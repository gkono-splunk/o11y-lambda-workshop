#!/usr/bin/env python3
import argparse
# import logging
import shlex
import subprocess
from time import sleep


parser = argparse.ArgumentParser(
    prog='send_message',
    description='Sends a message to your Lambda Producer\'s endpoint'
)

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


# Get endpoint URL
endpoint = subprocess.run(
    shlex.split(
        "terraform output -raw base_url"),
    stdout=subprocess.PIPE,
    text=True
).stdout

# Define curl command
request = f"curl -d '{{ \"name\": \"{name}\", \"superpower\": \"{superpower}\" }}' {endpoint}"

count = 1000
while count > 0:
    print(f"{ count - 1 } calls left")
    count -= 1
    
    response = subprocess.run(
        shlex.split(request),
        stdout=subprocess.PIPE,
        text=True
    ).stdout
    print(response)

    sleep(1)
