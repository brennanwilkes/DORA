#!/usr/bin/env bash

LANGS="javascript|go|python|rust|c|cpp|java|php|swift|typescript"

IFS="|"
for lang in $LANGS
do
	echo "Searching for $lang repos" >&2
	gh search repos -L 500 --sort=stars --stars=2500..1000000 --language="$lang" | grep -oE '^[a-zA-Z0-9-]+/[a-zA-Z0-9-]+'
	sleep 60
done
