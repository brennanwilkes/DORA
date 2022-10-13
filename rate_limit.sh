#!/usr/bin/env bash
ROOT="$1"

log() {
	$ROOT/log.sh "$ROOT" "$@"
}

[[ -z "$2" ]] && {
	log "Querying for new rate_limit"
	RATE_LIMIT=$( gh api -H "Accept: application/vnd.github+json" "/rate_limit" | node "$ROOT/parse_pr_commit_json" 3 2>>"$ROOT/log" )
	log "Rate limit infomation:"
	log "$( echo $RATE_LIMIT | cut -d',' -f1 ) queries remaining"
	log "$( echo $RATE_LIMIT | cut -d',' -f2 ) rollover time ($(( $(( $( echo $RATE_LIMIT | cut -d',' -f2 ) - $( date +%s ) )) / 60 )) minutes away)"
	echo "$RATE_LIMIT"
	exit 0
}
REMAINING_QUERIES=$( echo "$2" | cut -d',' -f1 )
ROLLOVER_TIME=$( echo "$2" | cut -d',' -f2 )

[ $(( $REMAINING_QUERIES % 50 )) -eq 0 ] && {
	log "$REMAINING_QUERIES queries remaining"
	log "$ROLLOVER_TIME rollover time ($(( $(( $ROLLOVER_TIME - $( date +%s ) )) / 60 )) minutes away)"
}

[[ "$REMAINING_QUERIES" -le 2 ]] && {
	waitTime=$(( "$ROLLOVER_TIME" - "$( date +%s )" ))
	[[ "$waitTime" -gt 0 ]] && {
		log "Sleeping for $(( $waitTime + 10 )) seconds"
		sleep "$(( $waitTime + 10 ))"
	}
	log "Querying for new rate_limit"
	RATE_LIMIT=$( gh api -H "Accept: application/vnd.github+json" "/rate_limit" | node "$ROOT/parse_pr_commit_json" 3 2>>"$ROOT/log" )
	log "Rate limit infomation:"
	log "$( echo $RATE_LIMIT | cut -d',' -f1 ) queries remaining"
	log "$( echo $RATE_LIMIT | cut -d',' -f2 ) rollover time ($(( $(( $( echo $RATE_LIMIT | cut -d',' -f2 ) - $( date +%s ) )) / 60 )) minutes away)"
	echo "$RATE_LIMIT"
	exit 0
}
echo "$(( $REMAINING_QUERIES - 1 )),$ROLLOVER_TIME"
exit 0
