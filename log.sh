#!/usr/bin/env bash
ROOT="$1"
shift
echo "$(date) | $@" >>"$ROOT/log"
