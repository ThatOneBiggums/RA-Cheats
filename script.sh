#!/bin/sh

# Variables
VPN_IFACE=wg-mullvad
SQUID_CONFIG_FILE=/etc/squid/squid.conf

# Get current IP address of VPN interface
VPN_IFACE_IP=$(ifconfig $VPN_IFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')

# Check if VPN interface is up and exit if it isn't
if [ -z "$VPN_IFACE_IP" ]
then
        mullvad connect
        sleep 3
        VPN_IFACE_IP=$(ifconfig $VPN_IFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
else
        mullvad disconnect
        mullvad relay set location us sjc
        mullvad connect
        sleep 3
        VPN_IFACE_IP=$(ifconfig $VPN_IFACE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')
fi

# Check current IP for VPN interface in squid.conf file
VPN_CONFIG_IP=$(grep -m 1 "tcp_outgoing_address" $SQUID_CONFIG_FILE | awk '{print $2}' | egrep -o '([0-9]+\.){3}[0-9]+')

# Check if the config file matches the current VPN interface IP, and if so exit script
if [ "$VPN_IFACE_IP" = "$VPN_CONFIG_IP" ]
then
        exit 0;
fi

# Replace the previous IP address in the squid.conf file with the current VPN interface address
sed -ie 's/'"$VPN_CONFIG_IP"'/'"$VPN_IFACE_IP"'/' $SQUID_CONFIG_FILE

# Force reload of the new squid.conf file
squid -k reconfigure
systemctl restart danted
curl https://ipinfo.io/ip