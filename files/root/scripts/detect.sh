#!/bin/bash

# Cyborg Unplug detector script for RT5350f LittleSnipper. Detects user-selected
# target devices resourced from /www/config/. 
#
# NOTE: This is the USA version of the script and so does no
# de-authing/disconnection. That feature is solely for the 'international'
# version. It has no 'territory' or 'allout' mode, just pure detection and
# reporting.
# 
# Copyright (C) 2015 Julian Oliver 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
shopt -s nocasematch # Important

readonly SCRIPTS=/root/scripts
readonly LOGS=/www/logs/
readonly CAPDIR=/tmp
readonly CONFIG=/www/config
readonly FRAMES=5 # Number of de-auth frames to send. 10 a good hit/time tradeoff
readonly MODE=$(cat $CONFIG/mode) 

# Read in the user selected target devices and build the target string.
readonly SRCT=$(cat $CONFIG/targets | cut -d "," -f 2)
readonly TARGETS='@('$(echo $SRCT | sed 's/\ /\*\|/g')'*)'

<<<<<<< HEAD
=======
networks='' # Placeholder. Technically redundant.
>>>>>>> parent of e6b1790... Added an email notification in the case target devices are not detected within
seen=()
apid=0

# Make the activity page the default site page for connections during detection
# (only available over Ethernet) 
cp /www/active.php /www/index.php
rm -f $LOGS/detected
echo "This is our target list: "$TARGETS > $LOGS/targets

airmon-ng stop mon0 
killall horst

# Set to station mode (taking down 'hostapd') so that we have control of the NIC
wifi down
uci set wireless.@wifi-iface[0].mode="sta"
uci set wireless.@wifi-iface[0].disabled="0"
uci commit wireless
wifi up
sleep 3 # Important

# Extract and define a variable for our wireless NIC and bring it up in Monitor
# mode. We use $NIC to capture rather than the mon0 device created below. This
# is useful as we can set the channel of $NIC on the fly with iwconfig,
# automatically setting the channel of the mon0 device used to de-auth in turn.
readonly NIC=$(iw dev | grep Interface | awk '{ print $2 }')
ifconfig $NIC down
iwconfig $NIC mode Monitor
ifconfig $NIC up
sleep 3 # Important

# Create a monitor device for aireplay-ng to de-auth with. Aireplay will only
# work with an airmon-ng mon device, not $NIC.
airmon-ng start $NIC 
sleep 3 # Important

# Bring up the admin default VPN for sending alerts to users
killall openvpn vpn.sh
echo start > $CONFIG/vpnstatus
echo "0 plugunplug.ovpn" > $CONFIG/vpn
$SCRIPTS/vpn.sh &

alert() {
    tmail=false
    now=$(date +'%s')
    # TODO resolve how long the LED notification should run. Reset to 'detect' once
    # the owner has been notified by email? 
    $SCRIPTS/blink.sh target 
    # Have we already seen this target? 
    if [[ ! " ${seen[@]} " =~ "$target" ]]; then
        # Add target to array, with last seen seconds set to now
        tt=$target"|"$now
        seen=(${seen[@]} $tt)
        tmail=true
    else
        # No associative arrays in this version of bash. 
        # Can't return index on match. Have to iterate
        for index in $(seq 0 $((${#seen[@]}-1))); do
            # Calculate last seen delta
            tdelta=$(($now - ${seen[$index]/$target|/}))
            # Send alerts no more than once every 5mins (to avoid spamming)
            if [[ $tdelta -gt 300 ]]; then
                # Remove old entry from array
                unset seen[$index]
                tmail=true
            else
                # Don't send alert this round as device was just seen
                tmail=false
            fi
            echo "this is tdelta: "$tdelta
        done
    fi
    if [[ $(cat $CONFIG/networkstate) == "online" ]]; then
        if [ "$tmail" = true ]; then
            echo "Alerting Unplug owner"
            device=$(cat /www/data/devices | grep -i ${target:0:8} | cut -d ',' -f 1)
            # in case a stuck pid, from last time
            if [[ $apid != 0 ]]; then
                kill -9 $apid 
            fi
            $SCRIPTS/alert.sh "$device" $target &
            apid=$! # new PID 
            # Log this for the report page 
            echo $(date) "detected device" "$device" "with MAC addr" $target >> $LOGS/detected
        else
            echo "Device seen in the last 5 minutes, not alerting owner"
        fi
    else
        echo "Can't send alert. Unplug not online"
    fi
}

# Start horst with upper channel limit of 13 in quiet mode and a command hook
# for remote control (-X). Has to be backgrounded. We look for any traffic
horst -u 13 -q -i $NIC -o $CAPDIR/cap -X &
HPID=$!

#if [ $? -ne 0 ]; then # Test horst exit status 
#  # Something is wrong, like a dead mon0
#  # and/or NIC. Store settings and reboot.
#   touch $CONFIG/updated && reboot -n 
#fi

POLLTIME=13 # Seconds we wait for capture to find STA/BSSID pairs
horst -x channel_auto=1

$SCRIPTS/blink.sh detect 

while true;
        do
            echo "//------------------------------------------------------->"
            echo "Sleeping for " $POLLTIME " and writing capture log"
            sleep $POLLTIME
            # Sort associated clients into temporary pairing files. Channels are
            # not in the probed/association section of airodump-ng and so the
            # pairs need to be extraced and matched separately.
            cat $CAPDIR/cap | awk '{ print $2 $3 $4 $11 }' | sed 's/,/\ /g' | sort -u > $CAPDIR/pairs
            if [ -f $CAPDIR/pairs ]; then
<<<<<<< HEAD
                while read line;
                         do
                            arr=($line) # Array from the line
                            src=${arr[0]}; dst=${arr[1]}; BSSID=${arr[2]}; freq=${arr[3]}
                            echo $src $dst $BSSID $freq
                            if [[ $src != $BSSID ]]; then
                                STA=$src
                            else 
                                STA=$dst 
                            fi

                            if [[ "$STA" == $TARGETS ]]; then
                                target=$STA
                                alert
                            elif [[ "$BSSID" == $TARGETS ]]; then
                                target=$BSSID
                                alert
                            fi


                    done < $CAPDIR/pairs #EOF
=======
                    if [[ "$MODE" == "territory" ]]; then
                        kill -STOP $CPID
                    fi
                    while read line;
                             do
                                arr=($line) # Array from the line
                                src=${arr[0]}; dst=${arr[1]}; BSSID=${arr[2]}; freq=${arr[3]}
                                echo $src $dst $BSSID $freq
                                if [[ $src != $BSSID ]]; then
                                    STA=$src
                                else 
                                    STA=$dst 
                                fi

                                if [[ "$MODE" == "territory" && "$STA" == $TARGETS && "$BSSID" == $networks ]]; then
                                        target=$STA
                                        deauth
                                elif [[ "$STA" == $TARGETS ]]; then
                                    target=$STA
                                    if [[ "$MODE" == "allout" ]]; then
                                        deauth
                                    else
                                        alert
                                    fi
                                elif [[ "$BSSID" == $TARGETS ]]; then
                                    target=$BSSID
                                    if [[ "$MODE" == "allout" ]]; then
                                        deauth
                                    else
                                        alert
                                    fi
                                fi
                        done < $CAPDIR/pairs #EOF
>>>>>>> parent of e6b1790... Added an email notification in the case target devices are not detected within
            echo "Removing temporary files."
            rm -f $CAPDIR/pairs $CAPDIR/channels 
            horst -x pause
            rm -f $CAPDIR/cap
            horst -x outfile=$CAPDIR/cap
            horst -x resume 
        fi
done

