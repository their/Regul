#!/bin/sh
TMIN=58				#Below this temp, the frequency will be increased
TMAX=62				#Above this temp, the frequency will be decreased
REFRESH_TIMER=1200  #The temperature is checked every 1200s
FREQ_STEP=4 #Each step is 6.25MHz, so with FREQ_STEP=4 that's a 6.25*4=25MHz frequency increase of decrease
while true
do
	date
	echo TEMP REGULATION IS ACTIVE
	temp1=$(cgminer-api stats | grep temp1] | awk '{print $3}') 
	temp2=$(cgminer-api stats | grep temp2] | awk '{print $3}')
        if ! [ "$temp1" -eq "$temp1" ] 2> /dev/null || ! [ "$temp2" -eq "$temp2" ] 2> /dev/null
	then
		echo "Warning: temp1 or temp2 not an integer! Waiting 60s."
                echo "temp1: $temp1"
		echo "temp2: $temp2"
		sleep 60 # Wait 60 seconds. Cgminer is probably restarting.
		continue # Go to next loop iteration.
	fi
	maxtemp=$(( $temp1 > $temp2 ? $temp1 : $temp2 ))
	echo Temperature: $maxtemp
	freq=$(cgminer-api stats | grep frequency] | awk '{print $3}')
	echo Frequence: $freq
	if [ $maxtemp -gt $TMAX ] && [ $freq'' != "100" ]
	then 
		echo "Aaahhhhhh!! I'm burning!! $maxtemp Celsius degrees";
		newFreq=$(cat freqList | grep -A "$FREQ_STEP" "$freq:" | tail -n 1)
		echo New Frequency: $newFreq	
	        sed -i "/bitmain-freq/c\"bitmain-freq\" : \"$newFreq\"," /config/cgminer.conf;    
		echo Restarting...
		sleep 1s
		/etc/init.d/cgminer.sh restart
	elif [ $maxtemp -lt $TMIN ] && [ $freq'' != "500" ]
	then
		echo "Increase the power...!! Only $maxtemp Celsius degrees"
		newFreq=$(cat freqList | grep -B "$FREQ_STEP" "$freq:" | head -n 1)
		echo New Frequency: $newFreq
		sed -i "/bitmain-freq/c\"bitmain-freq\" : \"$newFreq\"," /config/cgminer.conf;
		echo Restarting
		sleep 1s
		/etc/init.d/cgminer.sh restart
	else
		echo "Temp OK: $maxtemp Celsius degrees";
	fi

	sleep $REFRESH_TIMER
done
