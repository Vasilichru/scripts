#!/bin/bash
#usage
# sudo ./add_wg_user.sh username
# $1 - username arg

#some vars
filepath="/etc/wireguard/"
wg_filename="$filepath""wg0.conf"
srv_keyfile="$filepath""server_public.key"


#create keys
wg genkey | tee $filepath$1_private.key | wg pubkey > $filepath$1_public.key


#client ip_addr_gen
new_ip=$(tail -4 $wg_filename | grep 'AllowedIPs' | awk -F. '{ new_octet = $4+1; print "10.10.0."new_octet"/32" }')


#add info to wg0.conf
echo -e "[Peer]\n#name = $1" \
	"\nPublicKey = $(cat $filepath$1_public.key)" \
	"\nAllowedIPs = $new_ip\n\n" >> $wg_filename


# create user_wg0.conf
echo -e "[Interface]\n# $1 user config" \
	"\nPrivateKey = " "$(cat $filepath$1_private.key)" \
	"\nAddress = $new_ip" \
	"\nDNS = 8.8.8.8" > $filepath$1_wg0.conf

echo -e "\n[Peer]" \
	"\nPublicKey = $(cat $srv_keyfile) \nAllowedIPs = 0.0.0.0/0 \nEndpoint = 217.196.98.82:51820" >> $filepath$1_wg0.conf


#service restart
systemctl stop wg-quick@wg0.service
systemctl start wg-quick@wg0.service


#qr code gen
qrencode -t ansiutf8 < $filepath$1_wg0.conf
