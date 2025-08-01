#!/bin/bash

# COMP2137 - Assignment 1
# System info script

HOSTNAME=$(hostname)
USERNAME=$(whoami)
DATE=$(date)

# OS info
source /etc/os-release
OS="$NAME $VERSION"
UPTIME=$(uptime -p)

# CPU info
CPU=$(lshw -class processor 2>/dev/null | grep 'product' | head -1 | cut -d: -f2)

# RAM
RAM=$(free -h | awk '/Mem:/ {print $2}')

# Disks
DISKS=$(lsblk -d -o model,size | grep -v "MODEL")

# Video
VIDEO=$(lshw -C display 2>/dev/null | grep "product" | head -1 | cut -d: -f2)

# IP + Gateway
IP=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
GATEWAY=$(ip route | grep default | awk '{print $3}')
DNS=$(grep nameserver /etc/resolv.conf | awk '{print $2}' | head -1)

# Users
USERS=$(who | awk '{print $1}' | sort | uniq | tr '\n' ',' | sed 's/,$//')

# Disk Space
DISKSPACE=$(df -h --output=target,avail | tail -n +2)

# Processes
PROCESSCOUNT=$(ps -e | wc -l)

# Load Avg
LOADAVG=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

# Ports
PORTS=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | grep -E '[0-9]+' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')

# UFW status
UFWSTATUS=$(sudo ufw status | head -1)

echo ""
echo "System Report for $HOSTNAME by $USERNAME on $DATE"
echo ""
echo "System Info"
echo "-----------"
echo "OS: $OS"
echo "Uptime: $UPTIME"
echo "CPU: $CPU"
echo "RAM: $RAM"
echo "Disk(s):"
echo "$DISKS"
echo "Video: $VIDEO"
echo "Host Address: $IP"
echo "Gateway IP: $GATEWAY"
echo "DNS Server: $DNS"
echo ""
echo "System Status"
echo "-------------"
echo "Users Logged In: $USERS"
echo "Disk Space:"
echo "$DISKSPACE"
echo "Process Count: $PROCESSCOUNT"
echo "Load Averages: $LOADAVG"
echo "Listening Network Ports: $PORTS"
echo "UFW Status: $UFWSTATUS"
echo ""

