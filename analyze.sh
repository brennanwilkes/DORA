#!/usr/bin/env bash

export REPO="$1"
export DEPLOYMENT="$2"
export START="$3"
export END="$4"

export hash=$( echo "$REPO" | shasum | cut -d' ' -f1)
export WORKING_DIR="$(pwd)/$hash"

#####

# echo -ne "Cloning repo ($REPO)...\r"
[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
tmpOutput="$(mktemp)"
gh repo clone "$REPO" "$WORKING_DIR" >"$tmpOutput" 2>"$tmpOutput" || {
	echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)" >&2
	cat "$tmpOutput" >&2
	rm "$tmpOutput"
	exit 1
}
rm "$tmpOutput"

cd "$WORKING_DIR"
[[ "$DEPLOYMENT" -eq 0 ]] && {
	export deployments=$( gh release list --repo "$REPO" -L 1000 | cut -f3 | tac )
}
[[ "$DEPLOYMENT" -eq 1 ]] && {
	export deployments=$( git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's/^refs\/tags\///g' )
}
n=$( echo "$deployments" | wc -l )


ss=$( date -d "$START" +%s )
es=$( date -d "$END" +%s )
delta=$(( $ss - $es ))
avg1=$(( $delta / $n ))
echo "$ss,$es,$delta,$n,$avg1"

analyzeDeployment() {
	i="$1"

	prev_tag=$( echo "$deployments" | head -n "$i" | tail -n1)
	tag=$( echo "$deployments" | head -n "$(( $i + 1 ))" | tail -n1 )

	prev_time=$( git log -1 --format=%ai "$prev_tag" )
	time=$( git log -1 --format=%ai "$tag" )

	[[ $( date -d "$prev_time" +%s ) -lt $( date -d "$END" +%s ) ]] && {
		return
	}

	[[ $( date -d "$time" +%s ) -gt $( date -d "$START" +%s ) ]] && {
		return
	}
	commits=$( git log --date=local --pretty=format:"%H %ad" --since "$prev_time" --until "$time" --first-parent | head -n-1 )

	time=$( echo "$time" | cut -d' ' -f1-2 )
	while IFS= read -r commit; do
		analyzeCommit "$commit" "$time" "$date" "$prev_tag" "$tag" &
	done <<< "$commits"
	wait
}

analyzeCommit() {
	commit="$1"
	time="$2"
	date="$3"
	prev_tag="$4"
	tag="$5"

	echo "$commit" | grep -E '^[^\s]+ [^\s]+' >/dev/null || {
		return
	}

	sha=$( echo "$commit" | cut -d' ' -f1 )
	date=$( echo "$commit" | cut -d' ' -f2- | cut -d' ' -f1-5 | xargs -I {} date -d "{}" )

	d1=$(date --date="$time" +%s)
	d2=$(date --date="$date" +%s)

	diff=$(( $d1 - $d2 ))

	echo "$(echo $prev_tag | tr -d , ),$(echo $tag | tr -d , ),$sha,$d1,$d2,$diff"

}

for i in $(seq 1 $(( $n - 1 )) )
do
	analyzeDeployment "$i" &
done
wait
rm -rf "$WORKING_DIR"
