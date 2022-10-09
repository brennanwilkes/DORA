#!/usr/bin/env bash


REPO="brnkl/BRNKL-functions"

# 0 = release
#TODO: Actions
DEPLOYMENT=0
START="Oct 10 2022"
END="Jan 01 2019"

############

WORKING_DIR="$(pwd)/temp"

#####

# gh auth status || gh auth login

# [ -d "$WORKING_DIR" ] && rm -rf "$WORKING_DIR"
# gh repo clone "$REPO" "$WORKING_DIR"
cd "$WORKING_DIR"

releases=$( gh release list --repo "$REPO" -L 100 | cut -f3  )
n=$( echo "$releases" | wc -l )

sum=0
count=0
for i in $(seq 1 $(( $n - 1 )) )
do
	prev_tag=$( echo "$releases" | head -n "$(( $i + 1))" | tail -n1 )
	prev_time=$( git log -1 --format=%ai "$prev_tag" )

	[[ $( date -d "$prev_time" +%s ) -lt $( date -d "$END" +%s ) ]] && {
		continue
	}

	tag=$( echo "$releases" | head -n "$i" | tail -n1)
	time=$( git log -1 --format=%ai "$tag" )

	[[ $( date -d "$time" +%s ) -gt $( date -d "$START" +%s ) ]] && {
		continue
	}

	# git log --date=local --pretty=format:"%H %ad %B" --since "$prev_time" --until "$time" --first-parent | head -n-1
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

[[ "$count" -gt 0 ]] && echo "Average $(( $sum / $count / 60 / 60 / 24 )) days"

# rm -rf "$WORKING_DIR"
