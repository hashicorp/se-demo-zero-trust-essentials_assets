#!/usr/bin/bash -l

# Turn off history to leave no tracks
set +o history

# Install a needed package. Most RATS are
# self-contained and do not need this step.
sudo apt install nmap -y 

# Look for our local CIDR
export ROUTE=$(sudo ip route | awk '{print $1;}'| grep -v default | grep "/")

# Just scan our immediate neighbours.
# This should be a slow process as to avoid
# probe suspicion from a defense-scanner. 
sudo nmap -O $ROUTE
