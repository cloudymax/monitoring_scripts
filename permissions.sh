#!/bin/bash
echo " " > output.txt
count=0

check_user(){
    echo "checking ${1}"
    az role assignment list --assignee $1 -o yaml >> output.txt
}

declare -a group_list=(
    "some_team"
)

for group in "${group_list[@]}"; do
    group_user_ids=$(az ad group member list --group ${group} --query [*].objectId | sed  's/\"//g;s/\,//g;s/\[//g;s/\]//g;s/ //g' |tail -n +2 )
    for id in ${group_user_ids}; do
        check_user $id
        ((++count))
    done
done
