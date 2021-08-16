#!/bin/bash

set -o nounset
set -o pipefail
#set -o errexit

systemctl_service=("cron" "postgres-listen")
cron_services=("cron-update.sh" "postgres-listen" "update-deploy-status.sh")
SshUser=$1
text_payload=""


#find logs from today
date=$(date +%Y-%m-%d)
hour=$(date +%H)
errors=0


display_time(){
#shamelessly lifted from the internet because im too lazy to write yet another bash time converter
#https://unix.stackexchange.com/questions/27013/displaying-seconds-as-days-hours-mins-seconds/338844
   T=$1
   D=$((T/60/60/24))
   H=$((T/60/60%24))
   M=$((T/60%60))
   S=$((T%60))
  text_payload=""$text_payload" \n"$D" days "$H" hours "$M" minutes "$S" seconds since last log created"
}

compare_epochs(){

                last_log=$(sudo -u "$SshUser" ls /home/"$SshUser"/update/logs |grep "$date" |tail -1 ;exit 0)
                year=$(cut -d'-' -f1 <<< "$last_log")
                month=$(cut -d'-' -f2 <<< "$last_log")
                day=$(cut -d'-' -f3 <<< "$last_log")
                hour=$(cut -d'-' -f4 <<< "$last_log")
                minute=$(cut -d'-' -f5 <<< "$last_log")
                second=$(cut -d'-' -f6 <<< "$last_log" | cut -d'.' -f1)

                logEpoch=$(date --date=""$month"/"$day"/"$year" "$hour":"$minute":"$second"" +"%s")
                dateEpoch=$(date +%s)
                epochDiff=$(( $dateEpoch - $logEpoch ))
                display_time "$epochDiff"
}

check_logs(){
if [ "$hour" -eq "23" ] || [ "$hour" -eq "24" ] || [ "$hour" -eq "00" ]; then
        text_payload=""$text_payload" \n ouside of normal update hours, no logs expected"
        date=$(date -d "yesterday 12:00" '+%Y-%m-%d')
        compare_epochs
else
        text_payload=""$text_payload" \n inside of normal update hours"
        logCount=$(sudo -u "$SshUser" ls /home/"$SshUser"/update/logs |grep -c "$date" ;exit 0)
        date=$(date +%Y-%m-%d)

        if [ "$logCount" -ne "0" ]; then
                compare_epochs
        else
                text_payload=""$text_payload" \n inside of normal update hours, but no logs found, testing with yesterday's date"
                date=$(date -d "yesterday 12:00" '+%Y-%m-%d')
                compare_epochs
        fi
fi
}

check_systemctl(){
#find if the service is running in systemctl
for t in ${systemctl_service[@]}; do
  echo $(systemctl status ${t} |grep "active (running)")
  check=$(systemctl status ${t} |grep -c "active (running)")

		if [ "$check" -lt "1" ]; then
                text_payload=""$text_payload" \n "${t}" check failed"
                errors=$(( "$errors" + 1))
        else
                text_payload=""$text_payload" \n "${t}" check passed"
        fi
done
}

check_cron(){
#find if the service is in the crontab and enabled
for v in ${cron_services[@]}; do
  check=$(sudo -u "$SshUser" crontab -l |grep -c ${v} ;exit 0)

        if [ "$check" -gt "0" ]; then

                secondCheck=$(sudo -u "$SshUser"  crontab -l |grep ${v} |grep "*" |grep -c "#" ;exit 0)
                        if [ "$secondCheck" -eq "0" ]; then
                                text_payload=""$text_payload" \n "${v}" is in cron and is enabled"
                        else
                                text_payload=""$text_payload" \n "${v}" is in cron but disabled!!"
                                let errors+=1
                        fi

        else
                text_payload=""$text_payload" \n "${v}" is not in cron"
        fi
done
}

export_json(){

        hours_since=$(echo "scale=2; "$epochDiff" / 60 /60" | bc)
        echo -e "$text_payload"
        text_payload=$(echo -e "$text_payload")

        json_payload=$(echo '{"'hours_since_last_log'":"'${hours_since}'","'errors_found'":"'${errors}'","'text_payload'":"'${text_payload}'"}')

        logger "$json_payload"

        gcloud logging write log "$json_payload" --payload-type=json
}


check_systemctl
check_cron
check_logs
export_json
