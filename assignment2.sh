#!/bin/bash

# Simple, readable helper
say(){ echo -e "\n==> $*"; }

# must be root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."; exit 1
fi

say "Assignment 2 setup script starting…"

# ------ Network (192.168.16.21/24) ------
# Find the interface currently on 192.168.16.x
NET_IF=$(ip -o -4 addr show | awk '/192\.168\.16\./{print $2; exit}')

if [ -n "$NET_IF" ]; then
  say "Configuring $NET_IF with static 192.168.16.21/24"
  # write a small netplan drop-in that only touches the 192.168.16 interface
  cat >/etc/netplan/99-assign2.yaml <<EOFN
network:
  version: 2
  ethernets:
    $NET_IF:
      dhcp4: false
      addresses: [192.168.16.21/24]
      routes:
        - to: 0.0.0.0/0
          via: 192.168.16.2
      nameservers:
        addresses: [1.1.1.1,8.8.8.8]
EOFN

  netplan apply || { echo "netplan apply failed"; exit 1; }
  say "netplan applied"

  # /etc/hosts: ensure only the correct mapping for server1
  say "Updating /etc/hosts for server1"
  sed -i -E '/\sserver1(\s|$)/d' /etc/hosts
  grep -q '^192\.168\.16\.21\s+server1$' /etc/hosts || echo '192.168.16.21 server1' >> /etc/hosts
else
  echo "Could not find an interface on 192.168.16.x — skipping netplan step."
fi

# (Software + Users sections will be added next)
say "Network section done."
# ------ Software Setup ------
say "Checking and installing software..."

for pkg in apache2 squid; do
  if ! dpkg -s "$pkg" &>/dev/null; then
    say "Installing $pkg..."
    apt-get install -y "$pkg"
  else
    say "$pkg already installed"
  fi

  say "Ensuring $pkg is enabled and running..."
  systemctl enable --now "$pkg"
done

say "Software section done."

# ------ User Setup (part 1) ------
say "Creating user accounts..."

USERLIST="dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda"

for user in $USERLIST; do
  if id "$user" &>/dev/null; then
    say "User $user already exists"
  else
    say "Creating user: $user"
    useradd -m -s /bin/bash "$user"
  fi

  # home dir, .ssh setup
  SSH_DIR="/home/$user/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  chown "$user:$user" "$SSH_DIR"
done

say "Users created and .ssh directories prepared."

# ------ User Setup (part 2: SSH Keys + sudo for dennis) ------
say "Creating ssh keys and authorized_keys..."

for user in $USERLIST; do
  SSH_DIR="/home/$user/.ssh"
  AUTH_KEYS="$SSH_DIR/authorized_keys"

  # Generate RSA key if missing
  if [ ! -f "$SSH_DIR/id_rsa.pub" ]; then
    say "Generating RSA key for $user"
    sudo -u "$user" ssh-keygen -q -t rsa -b 2048 -f "$SSH_DIR/id_rsa" -N ""
  fi

  # Generate ED25519 key if missing
  if [ ! -f "$SSH_DIR/id_ed25519.pub" ]; then
    say "Generating ED25519 key for $user"
    sudo -u "$user" ssh-keygen -q -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
  fi

  # Add both keys to authorized_keys (if not already there)
  for keyfile in "$SSH_DIR/id_rsa.pub" "$SSH_DIR/id_ed25519.pub"; do
    grep -qF "$(cat "$keyfile")" "$AUTH_KEYS" 2>/dev/null || cat "$keyfile" >> "$AUTH_KEYS"
  done

  chown "$user:$user" "$AUTH_KEYS"
  chmod 600 "$AUTH_KEYS"
done

say "Setting up dennis for sudo and extra key..."

# Add dennis to sudo group
usermod -aG sudo dennis

# Add extra key to dennis' authorized_keys if missing
EXTRA_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
grep -qF "$EXTRA_KEY" /home/dennis/.ssh/authorized_keys || echo "$EXTRA_KEY" >> /home/dennis/.ssh/authorized_keys

say "User config completed."

