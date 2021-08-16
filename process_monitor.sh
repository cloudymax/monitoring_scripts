#!/bin/bash

temp_list="/tmp/process_list.txt"
temp_data="/tmp/process_list_data.txt"
final="/tmp/process_list_final.txt"

sudo rm "$temp_data"
sudo rm "$temp_list"
sudo rm "$final"



list=$(ps -e -o user,pid,ppid,%mem,%cpu,command --sort=-%cpu |head -20 > "$temp_list")

echo "{" >> "$temp_data"

for (( i=0; i < 10; i++ ));
do

	incrementor=$(( "$i" + 2 ))
	user=$(cat "$temp_list" |head -"$incrementor" |tail -1 |awk '{print $1}')
	pid=$(cat "$temp_list" |head -"$incrementor"  |tail -1 |awk '{print $2}')
	ppid=$(cat "$temp_list" |head -"$incrementor"  |tail -1 |awk '{print $3}')
	mem=$(cat "$temp_list" |head -"$incrementor"  |tail -1 |awk '{print $4}')
	cpu=$(cat "$temp_list" |head -"$incrementor"  |tail -1 |awk '{print $5}')
	cmd=$(cat "$temp_list" |head -"$incrementor"  |tail -1 | awk '{$1=$2=$3=$4=$5=""; print $0}')
	
	var=$(echo '"process_'$i'":{"user":"'${user}'","pid":"'${pid}'","ppid":"'${ppid}'","mem":"'${mem}'","cpu":"'${cpu}'","cmd":"'${cmd}'"}')
	
	if [ "$i" != "9" ]; then
		echo $var, >> "$temp_data"
	else 
		echo $var"}" >> "$temp_data"
	fi

done

cat "$temp_data" | tr -d " \t\n\r"  >> "$final"
var=$(cat "$final")

logger $var

gcloud logging write walmart-top-processes-log "$var" --payload-type=json

