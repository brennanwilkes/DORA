#!/usr/bin/env bash

export REPO="$1"
export DEPLOYMENT="$2"
export START="$3"
export END="$4"
export ROOT="$( pwd )"

export hash=$( echo "$REPO" | shasum | cut -d' ' -f1)
export WORKING_DIR="$ROOT/$hash"

#####

log() {
	$ROOT/log.sh "$ROOT" "$@"
}


RATE_LIMIT=$( $ROOT/rate_limit.sh "$ROOT" )

[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
gh repo clone "$REPO" "$WORKING_DIR" >>log 2>>log || {
	echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
	exit 1
}
rm -rf "$WORKING_DIR/*"

cd "$WORKING_DIR"
[[ "$DEPLOYMENT" -eq 0 ]] && {
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	log "Using gh releases strategy. Requesting releases from GitHub"
	export deployments=$( gh release list --repo "$REPO" -L 1000 2>>"$ROOT/log" | cut -f3 | tac )
}
[[ "$DEPLOYMENT" -eq 1 ]] && {
	log "Using git tags strategy. Requesting releases from local repo"
	export deployments=$( git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's/^refs\/tags\///g' )
}
n=$( echo "$deployments" | wc -l )
log "Found $n deployments"

[[ "$n" -gt 2 ]] && {
	first_tag=$( echo "$deployments" | head -n1 )
	first_time=$( git log -1 --format=%ai "$first_tag" )
	last_tag=$( echo "$deployments" | tail -n1 )
	last_time=$( git log -1 --format=%ai "$last_tag" )
	ss=$( date -d "$last_time" +%s )
	es=$( date -d "$first_time" +%s )
	delta=$(( $ss - $es ))
	avg1=$(( $delta / $(( $n - 2 )) ))
} || {
	ss=$( date -d "$START" +%s )
	es=$( date -d "$END" +%s )
	delta=$(( $ss - $es ))
	avg1=$(( $delta / $n ))
}

log "Time used: $es -> $ss with delta ($delta) and average ($avg1)"
echo "$ss,$es,$delta,$n,$avg1"

for i in $(seq 1 $(( $n - 1 )) )
do
	log "Checking deployment $i"

	prev_tag=$( echo "$deployments" | head -n "$i" | tail -n1)
	tag=$( echo "$deployments" | head -n "$(( $i + 1 ))" | tail -n1 )

	prev_time=$( git log -1 --format=%ai "$prev_tag" )
	time=$( git log -1 --format=%ai "$tag" )

	[[ $( date -d "$prev_time" +%s ) -lt $( date -d "$END" +%s ) ]] && {
		continue
	}

	[[ $( date -d "$time" +%s ) -gt $( date -d "$START" +%s ) ]] && {
		continue
	}

	log "Using $prev_tag -> $tag"
	log "Using $prev_time -> $time"

	# commits=$( git log --date=local --pretty=format:"%H %ad" --since "$prev_time" --until "$time" | head -n-1 )
	RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
	commits=$( gh api "/repos/$REPO/compare/$prev_tag...$tag" 2>>"$ROOT/log" | node "$ROOT/parse_pr_commit_json.js" 4 2>/dev/null )

	log Found $( echo "$commits" | wc -l ) commits

	time=$( echo "$time" | cut -d' ' -f1-2 )
	while IFS= read -r commit; do
		echo "$commit" | grep -E '^[^\s]+ [^\s]+' >/dev/null || {
			continue
		}
		sha=$( echo "$commit" | cut -d' ' -f1 )
		d1=$(date --date="$time" +%s)
		d2=$( echo "$commit" | cut -d' ' -f2 )
		diff=$(( $d1 - $d2 ))
		echo "$(echo $prev_tag | tr -d , ),$(echo $tag | tr -d , ),$sha,$d1,$d2,$diff"

	done <<< "$commits"
done
[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
