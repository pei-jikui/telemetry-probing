#!/usr/bin/python

import json
import requests
import sys
import socket 
import os

def tcp_send(host, port, message):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # TODO connect exception
    # TODO timeout setting
    sock.connect((host, port))
    sock.send(message)
    sock.close()

event_listener = {
    'host': os.getenv('event_listener_host'),
    'port': os.getenv('event_listener_port')
}

if event_listener['host'] == None or event_listener['port'] == None:
    sys.exit(1)

message = {}
if len(sys.argv) < 3:
    sys.exit(1)

try:
    resp = requests.get(
        url='http://%s:%s' % (sys.argv[1], sys.argv[2]),
        timeout=2)
    resp.raise_for_status()
except requests.HTTPError as err:
    # if err.response.status_code == 400:
    #     sys.exit(1)
    sys.exit(1)

sys.exit(0)
# if __name__ == '__main__':
#     tcp_send(event_listener['host'], event_listener['port'], "asjfaiowfjaiowfji")