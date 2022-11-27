#!/usr/bin/env bash

REPO="$1"

ROOT="$( pwd )"
hash=$( echo "$REPO" | shasum | cut -d' ' -f1 )
WORKING_DIR="$ROOT/$hash"

[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
