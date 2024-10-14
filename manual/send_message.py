#!/usr/bin/env python3
import os
from time import sleep


print("Enter your Name (e.g. Damian, Buttercup, etc.)")
name = input("> ")

print("Enter your Superpower (e.g. flight, super-strength, observability)")
superpower = input("> ")

message = f"curl -d '{{ \"name\": \"{name}\", \"superpower\": \"{superpower}\" }}' \"$(terraform output -raw base_url)\""

count = 500

while count > 0:
    print(f"{ count - 1 } calls left")
    message_response = os.system(message)
    print(message_response)
    count -= 1
    sleep(3)
