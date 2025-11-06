#!/bin/sh
# Entrypoint script to toggle between SNMP v2 and SNMP v3 based on arguments

# Check if any v3-related flags are present in arguments
if echo "$@" | grep -q -- '--v3-user'; then
  # Run with supplied arguments (assume v3)
  exec snmpsim-command-responder "$@"
else
  # No v3 flags, run with default v2 arguments plus any extra user args
  exec snmpsim-command-responder --agent-udpv4-endpoint=0.0.0.0:161 --data-dir=/data "$@"
fi
