#!/usr/bin/bash -l
# Copyright IBM Corp. 2022, 2024
# SPDX-License-Identifier: MPL-2.0


# Turn off history to leave no tracks
set +o history

# Look for our local CIDR
export ROUTE=$(sudo ip route | awk '{print $1;}'| grep -v default | grep "/")

# Show a list of known targets. This step is not
# required in a direct recognizance exercise and
# we have this here just for demo purposes.
nmap -n -sn $ROUTE -oG - | awk '/Up$/{print $2}'

# Store a list of neighbours
export TARGET_LIST=$(nmap -n -sn $ROUTE -oG - | awk '/Up$/{print $2}')

# These are here to make that list easy to read
# on the screen
echo 
echo 

# Loop through each target and reveal each public
# ip accoring to the Cloud provider.
for TARGET_HOST in $TARGET_LIST
do
  ssh -q -i /home/ubuntu/private.key ubuntu@$TARGET_HOST \
  -o "StrictHostKeyChecking no" 'curl -s http://checkip.amazonaws.com'
done
