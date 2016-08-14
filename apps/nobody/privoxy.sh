#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ $VPN_ENABLED == "no" ]]; then
	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"
else
	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# run script to check ip is valid for tun0
	source /home/nobody/checkip.sh

	if [[ $ENABLE_PRIVOXY == "yes" ]]; then
		echo "[info] Configuring Privoxy"...
		mkdir -p /config/privoxy

		if [[ ! -f "/config/privoxy/config" ]]; then
			cp -R /etc/privoxy/ /config/
		fi

		LAN_IP=$(hostname -i)

		sed -i -e "s/confdir \/etc\/privoxy/confdir \/config\/privoxy/g" /config/privoxy/config
		sed -i -e "s/logdir \/var\/log\/privoxy/logdir \/config\/privoxy/g" /config/privoxy/config

		sed -i -e "/listen-address/d" /config/privoxy/config
		# capture system interfaces, could be connected to multiple docker networks
		INTERFACES=$(for i in /sys/class/net/*; do if [ "`cat $i/type`" == "1" ]; then basename $i; fi; done)
		for int in $INTERFACES; do
			LAN_IP=$(ip addr show $int | grep inet[^6] | awk '{ print gensub(/\/[0-9]+/, "", 1, $2) }')
			echo "listen-address $LAN_IP:8118" >> /config/privoxy/config
		done
		echo "[info] All checks complete, starting Privoxy..."

		/usr/bin/privoxy --no-daemon /config/privoxy/config
	else
		echo "[info] Privoxy set to disabled"
	fi
fi

