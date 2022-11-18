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

[ -d "$WORKING_DIR" ] || {
	gh repo clone "$REPO" "$WORKING_DIR" >>log 2>>log || {
		echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
		exit 1
	}
	rm -rf "$WORKING_DIR/*"
}

cd "$WORKING_DIR"
[[ "$DEPLOYMENT" -eq 0 ]] && {
	log "Using gh releases strategy. Requesting releases from GitHub"
	for i in $( seq 1 10 )
	do
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		DATA=$( gh release list --repo "$REPO" -L 1000 2>>"$ROOT/log" )
		[[ "$?" -eq 0 ]] && break
	done
	export deployments=$( echo "$DATA" | cut -f3 | tac | node "$ROOT/custom_tag_sort.js" "$END" " $START" )
}
[[ "$DEPLOYMENT" -eq 1 ]] && {
	log "Using git tags strategy. Requesting releases from local repo"
	export deployments=$( git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's/^refs\/tags\///g' | grep -E '^v?[0-9]+\.[0-9]+' | node "$ROOT/custom_tag_sort.js" "$END" " $START")
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
	avg1=$(( $delta / $(( $n - 1 )) ))
} || {
	ss=$( date -d "$START" +%s )
	es=$( date -d "$END" +%s )
	delta=$(( $ss - $es ))
	avg1=$(( $delta / $n ))
}

log "Time used: $es -> $ss with delta ($delta) and average ($avg1)"
echo "$ss,$es,$delta,$n,$avg1"


processCommit(){
	commit="$1"
	time="$2"
	d1="$time"
	prev_tag="$3"
	tag="$4"

	echo "$commit" | grep -E '^[^\s]+ [^\s]+' >/dev/null || {
		return
	}
	sha=$( echo "$commit" | cut -d' ' -f1 )
	d2=$( echo "$commit" | cut -d' ' -f2 )
	diff=$(( $d1 - $d2 ))
	diffSha=$( git diff $sha~1 $sha 2>/dev/null | grep -Ev -e '^diff --git' -e '^---' -e '^\+\+\+' -e '^index [0-9a-z]+\.\.[0-9a-z]+ [0-9a-z]+$' | shasum | cut -d' ' -f1 )
	[[ "$diffSha" = "da39a3ee5e6b4b0d3255bfef95601890afd80709" ]] && {
		diffSha="$( date +"%T.%N" | shasum | cut -d' ' -f1 )"
	}

	echo "$(echo $prev_tag | tr -d , ),$(echo $tag | tr -d , ),$sha,$d1,$d2,$diff,$diffSha"
}

totalCommits=0
for i in $(seq 1 $(( $n - 1 )) )
do

	prev_tag=$( echo "$deployments" | head -n "$i" | tail -n1)
	tag=$( echo "$deployments" | head -n "$(( $i + 1 ))" | tail -n1 )

	prev_time=$( git log -1 --format=%ai "$prev_tag" )
	time=$( git log -1 --format=%ai "$tag" )

	[[ "$DEPLOYMENT" -eq 0 ]] && {
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		remote_time=$( gh api "/repos/$REPO/releases/tags/$tag" | node "$ROOT/parse_pr_commit_json.js" 9 2>/dev/null )
		[[ $( date -d "$remote_time" +%s ) -gt $( date -d "$time" +%s ) ]] && time="$remote_time"
		RATE_LIMIT="$( $ROOT/rate_limit.sh "$ROOT" $RATE_LIMIT )"
		remote_prev_time=$( gh api "/repos/$REPO/releases/tags/$prev_tag" | node "$ROOT/parse_pr_commit_json.js" 9 2>/dev/null )
		[[ $( date -d "$remote_prev_time" +%s ) -gt $( date -d "$prev_time" +%s ) ]] && prev_time="$remote_prev_time"
	}

	[[ $( date -d "$prev_time" +%s ) -lt $( date -d "$END" +%s ) ]] && {
		continue
	}

	[[ $( date -d "$time" +%s ) -gt $( date -d "$START" +%s ) ]] && {
		continue
	}

	[[ "$( echo $prev_tag | grep -oE '^v?[0-9]+' | tr -d 'v' )" -ne "$( echo $tag | grep -oE '^v?[0-9]+' | tr -d 'v' )" ]] && {
		[[ -z "$( echo $tag | grep -oE '^v?[0-9]+\.0' )" ]] && {
			log "SKIPPING $prev_tag -> $tag due to major/minor version mismatch"
			continue
		}
	}

	log "Using $prev_tag -> $tag"
	log "Using $prev_time -> $time"

	set_diff_tags=$( echo "$deployments" | head -n "$i" | tail -n 25 | xargs )
	commits=$( git rev-list "$tag" --not $set_diff_tags --date=local --format="%at" | paste - -  | cut -d' ' -f2- | tr '\t' ' ' )

	log Found $( echo "$commits" | wc -l ) commits


	[[ $( echo "$commits" | wc -l ) -gt 1000 ]] && [[ -z "$( echo $tag | grep -Eo '^v?[0-9]+.[0-9]+.0' )" ]] && {

		prev_major=$( echo $prev_tag | grep -oE '^v?[0-9]+' | tr -d 'v' )
		major=$( echo $tag | grep -oE '^v?[0-9]+' | tr -d 'v' )

		prev_minor=$( echo $prev_tag | grep -oE '^v?[0-9]+\.[0-9]+' | grep -Eo '[0-9]+$' )
		minor=$( echo $tag | grep -oE '^v?[0-9]+\.[0-9]+' | grep -Eo '[0-9]+$' )

		prev_patch=$( echo $prev_tag | grep -oE '^v?[0-9]+\.[0-9]+\.[0-9]+' | grep -Eo '[0-9]+$' )
		patch=$( echo $tag | grep -oE '^v?[0-9]+\.[0-9]+\.[0-9]+' | grep -Eo '[0-9]+$' )

		[[ "$patch" -ne "$(( $prev_patch + 1 ))" ]] && [[ "$minor" -ne "$(( $prev_minor + 1 ))" ]] && {
			log "SKIPPING $prev_tag -> $tag due to exes commits (likely invalid version)"
			continue
		}
	}

	totalCommits=$(( $totalCommits + $( echo "$commits" | wc -l ) ))

	max_commit_date=$( echo "$commits" | cut -d' ' -f2 | awk 'BEGIN{a=0}{if ($1>0+a) a=$1} END{print a}' )
	time=$( echo "$time" | cut -d' ' -f1-2 )
	time=$( date --date="$time" +%s )
	[[ "$time" -lt "$max_commit_date" ]] && time="$max_commit_date"

	N=16
	while IFS= read -r commit; do
		((i=i%N)); ((i++==0)) && wait
		processCommit "$commit" "$time" "$prev_tag" "$tag" &
	done <<< "$commits"
	wait
done
log "Processed $totalCommits total commits in anaylze step"

cd "$ROOT"
