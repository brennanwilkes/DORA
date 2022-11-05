#!/usr/bin/env bash
ROOT="$1"
RATE_LIMIT="$2"
IS_SEARCH="$3"

log() {
	$ROOT/log.sh "$ROOT" "$@"
}

[[ -z "$RATE_LIMIT" ]] || [[ "$IS_SEARCH" = 1 ]] && {
	[[ -z "$2" ]] && log "Querying for new rate_limit"
	for i in $( seq 1 10 )
	do
		DATA=$( gh api -H "Accept: application/vnd.github+json" "/rate_limit" 2>>"$ROOT/log" )
		[[ "$?" -eq 0 ]] && break
	done
	RATE_LIMIT=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json" 3 2>>"$ROOT/log" )

	[[ -z "$2" ]] && {
		log "Rate limit infomation:"
		log "$( echo $RATE_LIMIT | cut -d',' -f1 ) queries remaining"
		log "$( echo $RATE_LIMIT | cut -d',' -f2 ) rollover time ($(( $(( $( echo $RATE_LIMIT | cut -d',' -f2 ) - $( date +%s ) )) / 60 )) minutes away)"
		echo "$RATE_LIMIT"
		exit 0
	}
}
REMAINING_QUERIES=$( echo "$RATE_LIMIT" | cut -d',' -f1 )
ROLLOVER_TIME=$( echo "$RATE_LIMIT" | cut -d',' -f2 )
[[ "$IS_SEARCH" = 1 ]] && {
	REMAINING_QUERIES=$( echo "$RATE_LIMIT" | cut -d',' -f3 )
	ROLLOVER_TIME=$( echo "$RATE_LIMIT" | cut -d',' -f4 )
}

[ $(( $REMAINING_QUERIES % 50 )) -eq 0 ] && {
	log "$REMAINING_QUERIES queries remaining"
	log "$ROLLOVER_TIME rollover time ($(( $(( $ROLLOVER_TIME - $( date +%s ) )) / 60 )) minutes away)"
}

BUFFER=25
[[ "$IS_SEARCH" = 1 ]] && BUFFER=5

[[ "$REMAINING_QUERIES" -le "$BUFFER" ]] && {
	waitTime=$(( "$ROLLOVER_TIME" - "$( date +%s )" ))
	[[ "$waitTime" -gt 0 ]] && {
		log "Sleeping for $(( $waitTime + 10 )) seconds"
		sleep "$(( $waitTime + 10 ))"
	}
	log "Querying for new rate_limit"
	for i in $( seq 1 10 )
	do
		DATA=$( gh api -H "Accept: application/vnd.github+json" "/rate_limit" 2>>"$ROOT/log" )
		[[ "$?" -eq 0 ]] && break
	done
	RATE_LIMIT=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json" 3 2>>"$ROOT/log" )

	log "Rate limit infomation:"
	log "$( echo $RATE_LIMIT | cut -d',' -f1 ) queries remaining"
	log "$( echo $RATE_LIMIT | cut -d',' -f2 ) rollover time ($(( $(( $( echo $RATE_LIMIT | cut -d',' -f2 ) - $( date +%s ) )) / 60 )) minutes away)"
	echo "$RATE_LIMIT"
	exit 0
}
echo "$(( $REMAINING_QUERIES - 1 )),$ROLLOVER_TIME"
exit 0
