#!/usr/bin/env bash
export ROOT="$(pwd)"
REPO="$1"
SINCE="$2"
UNTIL="$3"
CUSTOM_LABELS="$4"
SINCE="$( date -u -d "@$SINCE" -I'seconds' 2>>"$ROOT/log" | cut -d'T' -f1 )"
UNTIL="$( date -u -d "@$UNTIL" -I'seconds' 2>>"$ROOT/log" | cut -d'T' -f1 )"

log() {
	$ROOT/log.sh "$ROOT" "$@"
}

RATE_LIMIT=$( $ROOT/rate_limit.sh "$ROOT" )

for i in $( seq 1 10 )
do
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	DATA=$( gh label list -L 1000 --repo "$REPO" 2>>"$ROOT/log" )
	[[ "$?" -eq 0 ]] && break
done
BUG_LABELS=$( echo "$DATA" | cut -d$'\t' -f1 | grep -iE -e "^bug" -e '[ :-]bug' -e "^confirm" -e "[^n]confirm" -e "important" -e "critical" -e "(high|top).*priority" -e "has.*(pr|pull)" -e "merge" -e '^(p|priority) ?([0-9]+|high|medium|low|mid)')


[[ -z "$CUSTOM_LABELS" ]] || {
	log "Adding custom labels $CUSTOM_LABELS"
	CUSTOM_LABELS=$( echo "$CUSTOM_LABELS" | xargs -n1 )
	BUG_LABELS+=$'\n'$(printf '%s' "$CUSTOM_LABELS")
}

log "Using labels $( echo $BUG_LABELS | paste -sd "," - )"
log "Using Time SINCE=$SINCE"
log "Using Time UNTIL=$UNTIL"

RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
PAGE=1
ISSUES=""

BUG_LABELS=$( echo "$BUG_LABELS" | paste -sd "," - )

for i in $( seq 1 10 )
do
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	DATA=$( gh api -X GET search/issues -f q="repo:$REPO is:closed label:$BUG_LABELS created:$SINCE..$UNTIL" -f per_page=100 -f "page=$PAGE" 2>>"$ROOT/log" )
	[[ "$?" -eq 0 ]] && break
done
NEW_ISSUES=$( echo "$DATA" | grep -oE "html_url.:.[^\"]+$REPO/issues/[0-9]+"| rev | cut -d'/' -f1 | rev | sort -n | uniq )


ISSUES="$NEW_ISSUES"
while [[ $( echo "$NEW_ISSUES" | wc -l ) -gt 1 ]]; do
	PAGE=$(( "$PAGE" + 1 ))
	log "Querying page $PAGE of issues"
	for i in $( seq 1 10 )
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		DATA=$( gh api -X GET search/issues -f q="repo:$REPO is:closed label:$BUG_LABELS created:$SINCE..$UNTIL" -f per_page=100 -f "page=$PAGE" 2>>"$ROOT/log" )
		[[ "$?" -eq 0 ]] && break
	done
	NEW_ISSUES=$( echo "$DATA" | grep -oE "html_url.:.[^\"]+$REPO/issues/[0-9]+"| rev | cut -d'/' -f1 | rev | sort -n | uniq )

	ISSUES=$( cat <( echo "$ISSUES" ) <( echo "$NEW_ISSUES" ) )
done

log Found $( echo "$ISSUES" | wc -l ) issues

for issue in $ISSUES
do
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" 2>>"$ROOT/log" | grep -Eo '[^/]+/[^/]+/pull/[0-9]+' | grep "$REPO" | sort | uniq | cut -d '/' -f4 )
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"

	ISSUE_DATA=$( gh api "/repos/$REPO/issues/$issue" 2>>"$ROOT/log" )

	created_at=$( echo "$ISSUE_DATA" | node "$ROOT/parse_pr_commit_json.js" 7 2>>"$ROOT/log" )
	bad_labels=$( echo "$ISSUE_DATA" | grep -iEo "$REPO/labels/[^\"]*" | grep -oE -e 'stalled' -e 'won.?t.*fix' -e 'blocked' -e 'invalid' -e 'feature' -e '^docs?$' -e '^documentation$' )

	[[ -z "$bad_labels" ]] || {
		log "found bad labels ($( echo $bad_labels | xargs )) for issue=$issue"
		continue
	}

	[[ -z "$created_at" ]] && {
		log "created_at for issue=$issue returned empty"
		continue
	}
	[[ -z "$pull_requests" ]] && {
		log "pull_requests for issue=$issue returned empty"
		continue
	}

	log "Issue $issue, created at $( date  -ud @$created_at 2>>"$ROOT/log" | cut -d' ' -f1-4 ). Pull requests: $( echo $pull_requests | xargs )"

	for pull_request in $pull_requests
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		DATA=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" )
		sha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 2 2>>"$ROOT/log" )
		diffSha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
		date=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 0 2>>"$ROOT/log" )
		log "$pull_request - Commit SHA: $sha - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"

		[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
			echo "$issue,$pull_request,$sha,$created_at,$date,$diffSha"
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			DATA=$( gh api "/repos/$REPO/commits/$sha" 2>>"$ROOT/log" )
			shaP=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 5 2>>"$ROOT/log" )
			diffSha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
			[[ -z "$shaP" ]] || {
				log "$pull_request - Parent SHA: $shaP - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"
				echo "$issue,$pull_request,$shaP,$created_at,$date,$diffSha"
			}
		}

		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		TIMELINE_SHAS=$( gh api "/repos/$REPO/issues/$pull_request/timeline" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 8 2>>"$ROOT/log" | sort | uniq )

		log Found $( echo "$TIMELINE_SHAS" | wc -l ) new shas on /timeline

		for sha in $TIMELINE_SHAS
		do
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			diffSha=$( gh api "/repos/$REPO/commits/$sha" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
			log "$pull_request - Timeline SHA: $sha - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"
			echo "$issue,$pull_request,$sha,$created_at,$date,$diffSha"
		done
	done
done

exit 0
