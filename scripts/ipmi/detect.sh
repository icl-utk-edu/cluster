#!/bin/sh

nmap -q -sP 172.29.101.0/24 -oG - | grep Up | awk '{print $2}'

