#!/bin/bash

# make a big ol' list of devices
cat /var/log/auth.log |grep -B2 "bind" |grep "New session" |awk '{print $8}' > list.txt


#count 'em
count=$( wc -l list.txt |awk '{print $1}')
end=$(( "$count" - 1 ))
readarray -t asset_array < list.txt

#go line by line
for(( i=0; i < "$end"; i++ ));
do
	counter=$(( "$i" + 1 ))
	port=${asset_array["${counter}"]}
	ss=$(ss |grep :"$port")

		echo " "
		echo " "
		echo "------------------------------------------------------------------------------------------------"
		echo "testing "$port""
		var=$(netstat -ant |grep :"$port")
		echo $var

	if [ ! -z "$ss" ]; then

		result=$(sudo -u some-admin ssh -o StrictHostKeyChecking=no -p $port some-admin@localhost)

		if [ ! -z "$ss" ]; then

			echo "unable to ssh"

			netstat -ant |grep "$port"
			sudo lsof -ti:$port
			PIDS=$(sudo lsof -ti:$port)

			if [ ! -z "$PIDS" ]; then
				echo "Killing PIDS "$PIDS""
				sudo kill -9 $PIDS

				echo "trying to ssh again..."
				result2=$(sudo -u some-admin ssh -o StrictHostKeyChecking=no -p $port some-admin@localhost)
				netstat -ant |grep "$port"
				sudo lsof -ti:$port
			else
				echo "no pids to kill"
			fi

			echo "------------------------------------------------------------------------------------------------"
			echo " "
			echo " "
			echo " "
			echo " "
		fi
	else
			echo "------------------------------------------------------------------------------------------------"
			echo " "
			echo " "
			echo " "
			echo " "


	fi
done


