#!/usr/bin/env python3
import argparse
import os
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

args = parser.parse_args()
name = args.name
superpower = args.superpower

message = f"curl -d '{{ \"name\": \"{name}\", \"superpower\": \"{superpower}\" }}' \"$(terraform output -raw base_url)\""

count = 500

while count > 0:
    print(f"{ count - 1 } calls left")
    message_response = os.system(message)
    print(message_response)
    count -= 1
    sleep(3)
