#!/bin/bash

established=$(netstat -ant | awk '{print $6}' | sort | uniq -c |grep "ESTABLISHED" | awk '{print $1}')

listen=$(netstat -ant | awk '{print $6}' | sort | uniq -c |grep "LISTEN" | awk '{print $1}')

ssconnections=$(ss | grep  ':ssh' | wc -l)

systemctl_abandoned=$(systemctl | grep -c "abandoned")

var=$(echo '{"connection_info":{"ss_ssh_connections":"'${ssconnections}'","netstat_established":"'${established}'","netstat_listen":"'${listen}'","systemctl_abandoned_sessions":"'${systemctl_abandoned}'"}}')

logger $var

gcloud logging write walmart-ssh-connections-log "$var" --payload-type=json