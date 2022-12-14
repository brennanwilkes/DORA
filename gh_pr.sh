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
BUG_LABELS=$( echo "$DATA" | cut -d$'\t' -f1 | grep -iE -e "^bug" -e '[ :/-]bug' -e "^confirm" -e "[^n]confirm" -e "important" -e "critical" -e "(high|top).*priority" -e "has.*(pr|pull)" -e '^(p|priority) ?([0-9]+|high|medium|low|mid)')


[[ -z "$CUSTOM_LABELS" ]] || {
	log "Adding custom labels $CUSTOM_LABELS"
	CUSTOM_LABELS=$( echo "$CUSTOM_LABELS" | tr -d "'" | xargs -n1 )
	BUG_LABELS+=$'\n'$(printf '%s' "$CUSTOM_LABELS")
}

log "Using Time SINCE=$SINCE"
log "Using Time UNTIL=$UNTIL"

t0=$( date +%s -d "$SINCE" )
tn=$( date +%s -d "$UNTIL" )

RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT 1 )"
TOTAL_COMMITS=$( gh api -i "/repos/$REPO/commits?per_page=1" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p' )
RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT 1 )"
FIRST_COMMIT=$( gh api "/repos/$REPO/commits?per_page=1&page=$TOTAL_COMMITS" | node parse_pr_commit_json.js 11 )
[[ -z "$FIRST_COMMIT" ]] || {
	[[ "$FIRST_COMMIT" -gt "$t0" ]] && t0="$FIRST_COMMIT"
}


INCREMENT=$(( 60 * 60 * 24 * 365 / 12 ))
ISSUES=""
BUG_LABELS=$( echo "$BUG_LABELS" | sed -E 's/(.*)/"\1"/g'  | paste -sd "," - )
log "Using labels $BUG_LABELS"

for ti in $( seq "$t0" "$INCREMENT" "$tn" )
do
	PAGE=1
	di0=$( date -u -d "@$ti" -I'seconds' 2>>"$ROOT/log" | cut -d'T' -f1 )
	di1=$( date -u -d "@$(( $ti + $INCREMENT ))" -I'seconds' 2>>"$ROOT/log" | cut -d'T' -f1 )

	log "Querying partial range for $di0 -> $di1"

	ISSUES=$( cat <( echo "$ISSUES" ) <( echo "$NEW_ISSUES" ) )
	while true; do
		log "Querying page $PAGE of issues"
		for i in $( seq 1 10 )
		do
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT 1 )"
			DATA=$( gh api -X GET search/issues -f q="repo:$REPO is:closed label:$BUG_LABELS created:$di0..$di1" -f per_page=100 -f "page=$PAGE" 2>>"$ROOT/log" )
			[[ "$?" -eq 0 ]] && break
		done
		NEW_ISSUES=$( echo "$DATA" | grep -oE "html_url.:.[^\"]+$REPO/(issues|pulls)/[0-9]+"| rev | cut -d'/' -f1 | rev | sort -n | uniq )
		log Query returned $( echo "$NEW_ISSUES" | wc -l ) issues
		ISSUES=$( cat <( echo "$ISSUES" ) <( echo "$NEW_ISSUES" ) )
		PAGE=$(( "$PAGE" + 1 ))
	[[ $( echo "$NEW_ISSUES" | wc -l ) -le 1 ]] && break
	done
done


checkTimelineSha(){
	sha="$1"
	pull_request="$2"
	date="$3"
	issue="$4"
	created_at="$5"
	diffSha=$( gh api "/repos/$REPO/commits/$sha" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
	log "$pull_request - Timeline SHA: $sha - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"
	echo "$issue,$pull_request,$sha,$created_at,$date,$diffSha,timeline"
}


totalIssues=$( echo "$ISSUES" | wc -l )
log "Found $totalIssues issues"

emptyPrs=0

issueIndex=0
for issue in $ISSUES
do
	issueIndex=$(( $issueIndex + 1 ))

	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	DATA=$( gh api "/repos/$REPO/issues/$issue/timeline" 2>>"$ROOT/log" )
	pull_requests=$( echo "$DATA" | grep -Eo "url.: ?.https...github.com/$REPO/pull/[0-9]+" | sort | uniq | cut -d '/' -f7 )
	direct_merge_commits=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json" 12 2>/dev/null )

	[[ -z "$pull_requests" ]] && [[ $( echo "$direct_merge_commits" | wc -c ) -le 10 ]] && {
		emptyPrs=$(( $emptyPrs + 1 ))
		log "pull_requests for issue=$issue returned empty ($emptyPrs so far)"
		continue
	}

	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	ISSUE_DATA=$( gh api "/repos/$REPO/issues/$issue" 2>>"$ROOT/log" )

	created_at=$( echo "$ISSUE_DATA" | node "$ROOT/parse_pr_commit_json.js" 7 2>>"$ROOT/log" )
	bad_labels=$( echo "$ISSUE_DATA" | grep -iEo "$REPO/labels/[^\"]*" | grep -oE -e 'stalled' -e 'won.?t.*fix' -e 'blocked' -e 'invalid' -e 'feature' -e '^docs?$' -e '^documentation$' -e 'do.not.*merge' )

	[[ -z "$bad_labels" ]] || {
		log "found bad labels ($( echo $bad_labels | tr -d "'" | xargs )) for issue=$issue"
		continue
	}

	[[ -z "$created_at" ]] && {
		log "created_at for issue=$issue returned empty"
		continue
	}

	log "Issue $issue ($issueIndex/$totalIssues), created at $( date  -ud @$created_at 2>>"$ROOT/log" | cut -d' ' -f1-4 ). Pull requests: $( echo $pull_requests | tr -d "'" | xargs )"

	[[ $( echo "$direct_merge_commits" | wc -c ) -gt 5 ]] && {
		log "Found direct_merge_commits $( echo $direct_merge_commits | tr -d "'" | xargs )"
		for sha in $direct_merge_commits
		do
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			checkTimelineSha "$sha" "DIRECT" "-1" "$issue" "$created_at" &
		done
		wait
	}

	for pull_request in $pull_requests
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		DATA=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" )
		sha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 2 2>>"$ROOT/log" )
		diffSha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
		date=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 0 2>>"$ROOT/log" )
		log "$pull_request - Commit SHA: $sha - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"

		[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
			echo "$issue,$pull_request,$sha,$created_at,$date,$diffSha,merge"
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			DATA=$( gh api "/repos/$REPO/commits/$sha" 2>>"$ROOT/log" )
			shaP=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 5 2>>"$ROOT/log" )
			diffSha=$( echo "$DATA" | node "$ROOT/parse_pr_commit_json.js" 6 2>>"$ROOT/log" | shasum | cut -d' ' -f1 )
			[[ -z "$shaP" ]] || {
				log "$pull_request - Parent SHA: $shaP - diff: $diffSha - date: $( date  -ud @$date 2>>"$ROOT/log" | cut -d' ' -f1-4 )"
				echo "$issue,$pull_request,$shaP,$created_at,$date,$diffSha,parent"
			}
		}

		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		TIMELINE_SHAS=$( gh api "/repos/$REPO/issues/$pull_request/timeline" 2>>/dev/null | node "$ROOT/parse_pr_commit_json.js" 8 2>>/dev/null | sort | uniq )

		log Found $( echo "$TIMELINE_SHAS" | wc -l ) new shas on /timeline

		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		for sha in $TIMELINE_SHAS
		do
			RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
			checkTimelineSha "$sha" "$pull_request" "$date" "$issue" "$created_at" &
		done
		wait
	done
done

exit 0
