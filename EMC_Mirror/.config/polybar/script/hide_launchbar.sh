#!/bin/bash

# Script to hide launchbar 

PIDFILE="/tmp/polybar_launchbar.pid"

kill "$(cat "$PIDFILE")" 2>/dev/null
rm -f "$PIDFILE"

