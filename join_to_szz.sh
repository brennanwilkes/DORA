#!/usr/bin/env bash

REPO="$1"
COMMIT_CACHE="$2"
SZZ_CACHE="$3"

while IFS='$\n' read -r line; do
	./find_fix_lines.sh "$line" "$REPO" "$COMMIT_CACHE" "$SZZ_CACHE"
done
