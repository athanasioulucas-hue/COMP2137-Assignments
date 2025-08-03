#!/bin/bash

trap '' SIGTERM SIGHUP SIGINT

VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -verbose)
      VERBOSE=true
      shift
      ;;
    -name)
      NEWNAME=$2
      CURRENTNAME=$(hostname)
      if [ "$CURRENTNAME" != "$NEWNAME" ]; then
        echo "$NEWNAME" > /etc/hostname
        hostnamectl set-hostname "$NEWNAME"
        sed -i "s/127.0.1.1.*/127.0.1.1\t$NEWNAME/" /etc/hosts
        $VERBOSE && echo "Changed hostname to $NEWNAME"
        logger "Hostname changed to $NEWNAME"
      else
        $VERBOSE && echo "Hostname already set"
      fi
      shift 2
      ;;
    -ip)
      NEWIP=$2
      NETFILE=$(find /etc/netplan -name "*.yaml" | head -n1)
      # just overwrite the existing IP in netplan
      sed -i "s/[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\/24/$NEWIP\/24/" "$NETFILE"
      netplan apply
      grep -q "$NEWIP" /etc/hosts || echo "$NEWIP $(hostname)" >> /etc/hosts
      $VERBOSE && echo "Set IP to $NEWIP"
      logger "IP changed to $NEWIP"
      shift 2
      ;;
    -hostentry)
      ENTRYNAME=$2
      ENTRYIP=$3
      grep -q "$ENTRYIP" /etc/hosts
      if [ $? -ne 0 ]; then
        echo "$ENTRYIP $ENTRYNAME" >> /etc/hosts
        $VERBOSE && echo "Added host entry for $ENTRYNAME"
        logger "Added host entry: $ENTRYNAME at $ENTRYIP"
      else
        $VERBOSE && echo "Host entry for $ENTRYNAME already there"
      fi
      shift 3
      ;;
    *)
      echo "Unknown option $1"
      shift
      ;;
  esac
done
