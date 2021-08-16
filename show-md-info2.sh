#! /bin/bash
pid=$$
(sleep 90; kill $pid && echo "error") &
watchdogpid=$!


# Gathers needed information for daily report from the MD.  Format wil be:
MD_PORT=$(psql -t -q --host=localhost --user=mdhost --dbname=DeviceService --command="SELECT port from device where type='MD' and assettag='$1'")

SSH="sudo -u some-admin ssh -o StrictHostKeyChecking=no -p "$MD_PORT" some-admin@localhost"

results=""


#USB information (ex: USB2 or USB3)
USB_type=$($SSH usb-devices | grep -q "3.0 Hub" && printf "USB3" || printf "USB2")
if test -z "$USB_type"
then
      echo "Error"; exit 0;
fi
results=$"${results}\n${USB_type}"

kernel_log=$($SSH grep -q "U1" /var/log/kern.log && echo " U1")
if test ! -z "$kernel_log"
then
	results=$"${results}\n${kernel_log}"
fi

store_number=$($SSH nmcli dev show enp1s0 | grep IP4.DOMAIN | awk '{print $2}' | tr -cd '[[:digit:]]' | sed 's/^0*//')
if test -z "$store_number"
then
      echo "Error"; exit 0;
fi
results=$"${results}\n${store_number}"


#GO information (AssetTag Serial etc)
headset_data=$($SSH sudo adb devices -l)
if test -z "$headset_data"
then
      echo "Error"; exit 0;
fi

hedset_count=$(grep -c "usb:" <<< "$headset_data")
count=$(( "$hedset_count" + 2 ))


for (( i=1; i < "$count"; i++ ));
do
	PORT=$($SSH sudo adb devices -l |grep "usb:" |awk '{print $3}' | tail -"$i" |head -1)
	SN=$($SSH sudo adb devices -l |grep "usb:" |awk '{print $1}' | tail -"$i" |head -1)
	BATTERY=$($SSH sudo adb -s $SN shell dumpsys battery | grep "Max charging current:" | xargs)
	DISK=$($SSH sudo adb -s $SN shell dumpsys diskstats | grep Data-Free)
	COUNT=$($SSH sudo adb -s $SN shell ls -Aq --color=never /sdcard/Android/data/some-data/files/Uploading 2> /dev/null | wc -l)

	if [ "$COUNT" -gt 0 ]; then
		COUNT="Uploading"
	else
		COUNT=""
	fi

	PLAYERSTATE=$($SSH sudo adb -s $SN shell pidof some-data > /dev/null || echo "PlayerNotRunning")
	INCVERSION=$($SSH sudo adb -s $SN shell getprop | grep ro.build.version.incremental)

	string=""$PORT" "$DISK" "$INCVERSION" "$PLAYERSTATE" "$BATTERY""
	results=$"${results}\n${string}"
done

echo -e "${results}"
kill $watchdogpid
