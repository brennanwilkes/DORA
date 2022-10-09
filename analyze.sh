#!/usr/bin/env bash


REPO="brnkl/BRNKL-functions"

# 0 = release
# 1 = tag
#TODO: Actions
DEPLOYMENT=1
START="Oct 10 2022"
END="Jan 01 2019"
VERBOSE=1

############

WORKING_DIR="$(pwd)/temp"

print_time() {
	minute=60
	hour=$((  $minute * 60 ))
	day=$(( $hour * 24 ))
	week=$(( $day * 7 ))
	month=$(( $day * 365 / 12 ))
	year=$(( $day * 365 ))
	[[ "$1" -gt "$year" ]] && echo "$(( $1 / $year )) years" && return
	[[ "$1" -gt "$month" ]] && echo "$(( $1 / $month )) months" && return
	[[ "$1" -gt "$week" ]] && echo "$(( $1 / $week )) weeks" && return
	[[ "$1" -gt "$day" ]] && echo "$(( $1 / $day )) days" && return
	[[ "$1" -gt "$hour" ]] && echo "$(( $1 / $hour )) hours" && return
	[[ "$1" -gt "$minute" ]] && echo "$(( $1 / $minute )) minutes" && return || echo "$1 seconds"
}

#####

echo -ne "Authenticating with GitHub...\r"
gh auth status >/dev/null 2>/dev/null || gh auth login

echo -ne "Cloning repo ($REPO)...\r"
[ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
gh repo clone "$REPO" "$WORKING_DIR" >/dev/null 2>/dev/null || {
	echo "Something went wrong cloning repo ($REPO) into ($WORKING_DIR)"
	exit 1
}
cd "$WORKING_DIR"
[[ "$DEPLOYMENT" -eq 0 ]] && {
	deployments=$( gh release list --repo "$REPO" -L 1000 | cut -f3 | tac )
}
[[ "$DEPLOYMENT" -eq 1 ]] && {
	deployments=$( git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's/^refs\/tags\///g' )
}
n=$( echo "$deployments" | wc -l )
sum=0
count=0
for i in $(seq 1 $(( $n - 1 )) )
do
	echo -ne "Calculating Lead Time for Changes: $(( $i * 100 / $n ))% Complete\r"
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
	commits=$( git log --date=local --pretty=format:"%H %ad" --since "$prev_time" --until "$time" --first-parent | head -n-1 )

	time=$( echo "$time" | cut -d' ' -f1-2 )
	while IFS= read -r commit; do

		echo "$commit" | grep -E '^[^\s]+ [^\s]+' >/dev/null || {
			continue
		}

		sha=$( echo "$commit" | cut -d' ' -f1 )
		date=$( echo "$commit" | cut -d' ' -f2- | cut -d' ' -f1-5 | xargs -I {} date -d "{}" )

		d1=$(date --date="$time" +%s)
		d2=$(date --date="$date" +%s)

		diff=$(( $d1 - $d2 ))

		sum=$(( $sum + $diff ))
		count=$(( $count + 1))
	done <<< "$commits"
done

ss=$( date -d "$START" +%s )
es=$( date -d "$END" +%s )
delta=$(( $ss - $es ))
avg1=$(( $delta / $n ))

echo "DORA Report for $REPO                    "
echo "Deployment Frequency every $( print_time $avg1 ). ($n deployments over $( print_time $delta ))"
[[ "$count" -gt 0 ]] && {
	avg2=$(( $sum / $count ))
	echo "Lead Time for Changes averages $( print_time $avg2 ). ($count commits across $n deployments over $( print_time $delta ))"
}

# rm -rf "$WORKING_DIR"
