#!/usr/bin/env bash

minute=60
hour=$((  $minute * 60 ))
day=$(( $hour * 24 ))
week=$(( $day * 7 ))
month=$(( $day * 365 / 12 ))
year=$(( $day * 365 ))
[[ "$1" -gt "$year" ]] && {
	val=$(( $1 / $year ))
	label="year"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
[[ "$1" -gt "$month" ]] && {
	val=$(( $1 / $month ))
	label="month"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
[[ "$1" -gt "$week" ]] && {
	val=$(( $1 / $week ))
	label="week"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
[[ "$1" -gt "$day" ]] && {
	val=$(( $1 / $day ))
	label="day"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
[[ "$1" -gt "$hour" ]] && {
	val=$(( $1 / $hour ))
	label="hour"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
[[ "$1" -gt "$minute" ]] && {
	val=$(( $1 / $minute ))
	label="minute"
	[[ "$val" -gt 1 ]] && label="${label}s"
	echo -e "$val $label"
	exit 0
}
val=$1
label="second"
[[ "$val" -gt 1 ]] && label="${label}s"
echo -e "$val $label"
exit 0
