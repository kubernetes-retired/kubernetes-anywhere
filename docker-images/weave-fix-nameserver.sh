#!/bin/sh -x
ip -4 addr show dev docker0 | grep -m1 -o 'inet [.0-9]*' | sed 's/inet \([.0-9]*\)/nameserver \1/' > /etc/resolv.conf
