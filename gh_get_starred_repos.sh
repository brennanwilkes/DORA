#!/usr/bin/env bash

LANGS="javascript|go|python|typescript|rust|c|cpp|java|php|swift"

IFS="|"
for lang in $LANGS
do
	echo "Searching for $lang repos" >&2
	gh search repos -L 1000 --archived=false --sort=stars --stars=1000..1000000 --language="$lang" | grep -oE '^[a-zA-Z0-9-]+/[a-zA-Z0-9-]+'
	sleep 60
done
