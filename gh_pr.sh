#!/usr/bin/env bash
export ROOT="$(pwd)"
REPO="$1"
SINCE="$2"
CUSTOM_LABELS="$2"
SINCE="$( date -u -d "@$SINCE" -I'seconds' | cut -d'+' -f1 )"

log() {
	$ROOT/log.sh "$ROOT" "$@"
}

RATE_LIMIT=$( $ROOT/rate_limit.sh "$ROOT" )

BUG_LABELS=$( gh label list -L 1000 --repo "$REPO" | cut -d$'\t' -f1 | grep -iE -e "bug" -e "^confirm" -e "[^n]confirm" -e "important" -e "critical" -e "(high|top).*priority" -e "has.*(pr|pull)" -e "merge" -e "major" -e '(p|priority) ?([0-9]+|high|medium|low|mid)')

[[ -z "$CUSTOM_LABELS" ]] || {
	CUSTOM_LABELS=$( echo "$CUSTOM_LABELS" | xargs -n1 )
	BUG_LABELS+=$'\n'$(printf '%s' "$CUSTOM_LABELS")
}

log "Using labels $( echo $BUG_LABELS | paste -sd "," - )"
log "Using Time SINCE=$SINCE"

RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
PAGE=1
ISSUES=""
NEW_ISSUES=$( gh api "/repos/$REPO/issues" --method GET -f label="$( echo $BUG_LABELS | paste -sd "," - )" -f state=closed -f per_page=100 -f page=$PAGE -f "since=$SINCE" | grep -oE "html_url.:.[^\"]+$REPO/issues/[0-9]+"| rev | cut -d'/' -f1 | rev | sort -n | uniq )
ISSUES="$NEW_ISSUES"
while [[ $( echo "$NEW_ISSUES" | wc -l ) -gt 1 ]]; do
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	PAGE=$(( "$PAGE" + 1 ))
	log "Querying page $PAGE of issues"
	NEW_ISSUES=$( gh api "/repos/$REPO/issues" --method GET -f label="$( echo $BUG_LABELS | paste -sd "," - )" -f state=closed -f per_page=100 -f "page=$PAGE" -f "since=$SINCE" | grep -oE "html_url.:.[^\"]+$REPO/issues/[0-9]+"| rev | cut -d'/' -f1 | rev | sort -n | uniq )
	ISSUES=$( cat <( echo "$ISSUES" ) <( echo "$NEW_ISSUES" ) )
done


log Found $( echo "$ISSUES" | wc -l ) issues

for issue in $ISSUES
do
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	pull_requests=$( gh api "/repos/$REPO/issues/$issue/timeline" 2>>"$ROOT/log" | grep -Eo '[^/]+/[^/]+/pull/[0-9]+' | grep "$REPO" | sort | uniq | cut -d '/' -f4 )
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	created_at=$( gh api "/repos/$REPO/issues/$issue" 2>>"$ROOT/log" | grep -Eo 'created_at[^,]*,' | head -n1 | cut -d':' -f2- | tr -d '"' | tr -d ',' )

	[[ -z "$created_at" ]] && {
		log "created_at for issue=$issue returned empty"
		continue
	}
	[[ -z "$pull_requests" ]] && {
		log "pull_requests for issue=$issue returned empty"
		continue
	}

	created_at=$( date --date="$created_at" +%s )

	log "Issue $issue, created at $created_at. Pull requests: $( echo $pull_requests | xargs )"

	for pull_request in $pull_requests
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		sha=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 2 2>/dev/null )
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		date=$( gh api "/repos/$REPO/pulls/$pull_request" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 0 2>/dev/null )
		log "$pull_request, Commit SHA: $sha, date: $date"

		[[ "$sha" != "undefined" ]] && [[ "$date" != "0" ]] && [[ "$date" -gt "$created_at"  ]] && {
			echo "$issue,$pull_request,$sha,$created_at,$date"
		}
	done
done
