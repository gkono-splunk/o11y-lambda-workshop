#!/usr/bin/env python3
import argparse
import os


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
    live_tail_command = f"aws --region us-east-1 logs start-live-tail --log-group-identifiers $(terraform output -raw {function_type.function}_log_group_arn)"
    os.system(live_tail_command)
else:
    pass