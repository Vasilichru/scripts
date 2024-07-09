#!/bin/bash

if [ $# -eq 0 ]
then
  echo -e "\n\n  === not enough arguments ===\n      usage: sudo $0 new_username\n\n"
  exit 0
fi

#some vars
filepath="/etc/wireguard/"
wg_filename="$filepath""wg0.conf"
srv_keyfile="$filepath""server_public.key"


#create keys
wg genkey | tee "$filepath$1_private.key"| wg pubkey > "$filepath$1_public.key"


#client ip_addr_gen
new_ip=$(tail -4 $wg_filename | grep 'AllowedIPs' | awk -F. '{ new_octet = $4+1; print "10.10.0."new_octet"/32" }')


#add info to wg0.conf
cat << EOF >> $wg_filename
[Peer]
#name = $1 
PublicKey = $(cat "$filepath$1_public.key")
AllowedIPs = $new_ip

EOF

# create user_wg0.conf
cat << EOF > "$filepath$1_wg0.conf" 
[Interface]
# $1 user config
PrivateKey = $(cat "$filepath$1_private.key")
Address = $new_ip
DNS = 8.8.8.8"

[Peer]
PublicKey = $(cat $srv_keyfile)
AllowedIPs = 0.0.0.0/0
Endpoint = 217.196.98.82:51820

EOF
#service restart
systemctl stop wg-quick@wg0.service
systemctl start wg-quick@wg0.service


#qr code gen
qrencode -t ansiutf8 < "$filepath$1_wg0.conf"