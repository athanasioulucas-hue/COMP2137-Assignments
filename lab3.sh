#!/bin/bash

VERBOSE=""
if [[ "$1" == "-verbose" ]]; then
  VERBOSE="-verbose"
fi

# Basic error handler
check_result() {
    if [[ $1 -ne 0 ]]; then
        echo "An error occurred during the script. Exiting."
        exit 1
    fi
}

# Copy config script to both servers
scp configure-host.sh remoteadmin@server1-mgmt:/root
check_result $?

scp configure-host.sh remoteadmin@server2-mgmt:/root
check_result $?

# Run on server1 (loghost)
ssh remoteadmin@server1-mgmt "/root/configure-host.sh $VERBOSE -name loghost -ip 192.168.16.241 -hostentry webhost 192.168.16.242"
check_result $?

# Run on server2 (webhost)
ssh remoteadmin@server2-mgmt "/root/configure-host.sh $VERBOSE -name webhost -ip 192.168.16.242 -hostentry loghost 192.168.16.241"
check_result $?

# Update local hosts file
./configure-host.sh $VERBOSE -hostentry loghost 192.168.16.241
check_result $?

./configure-host.sh $VERBOSE -hostentry webhost 192.168.16.242
check_result $?

echo "All tasks completed successfully."

