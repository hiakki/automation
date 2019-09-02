#!/bin/bash
# Author - Akshay Gupta
# Version - 1.0.0
# Description - Installs and Configures VPN Server in Ubuntu in just 1 click.
# Usage -
#
#	bash VPN_Server.sh
#	bash VPN_Server.sh 1		# For server setup
#	bash VPN_Server.sh 2		# To build client configs
#


# Get root access
read -p "This script requires root access. Press enter to continue."
if [ $(whoami) != root ]
then
	echo 'Not running as root. Terminating script.'
	exit
fi

installations() {

	if [ $(date | awk '{print $2 $3}') != $(ls -al /var/lib/apt/periodic/update-success-stamp | awk '{print $6 $7}') ]
	then
		apt update -y
		apt upgrade -y
		apt dist-upgrade -y
	fi
	
	# Installing nginx so that we can download our client key, certificates and ovpn files over http server
	apt install openvpn easy-rsa iptables-persistent nginx -y

}

server() {

	gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz > /etc/openvpn/server.conf
	make-cadir /etc/openvpn/easy-rsa
	cd /etc/openvpn/easy-rsa/
	ln -s openssl-1.0.0.cnf openssl.cnf
	if [ ! -e /etc/openvpn/dh4096.pem ]
	then
		read -p "Press enter to continue, the next step will take few minutes."
		openssl dhparam 4096 > /etc/openvpn/dh4096.pem
	fi
	mkdir -p keys
	source ./vars

	if [ ! -e /etc/openvpn/easy-rsa/keys/ca.crt ]
	then
		clear
		read -p "Press enter to if you want to remove $KEY_DIR, it contains all existing server and client keys, certificates from"
		./clean-all
		openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key
	fi
	if [ ! -e /etc/openvpn/easy-rsa/keys/ca.crt ]
	then
		./build-ca
	fi
	if [ ! -e /etc/openvpn/easy-rsa/keys/server.key ]
	then
		./build-key-server server
	fi
	sed -i 's/ca ca.crt/ca \/etc\/openvpn\/easy-rsa\/keys\/ca.crt/g' /etc/openvpn/server.conf
	sed -i 's/cert server.crt/cert \/etc\/openvpn\/easy-rsa\/keys\/server.crt/g' /etc/openvpn/server.conf
	sed -i 's/key server.key/key \/etc\/openvpn\/easy-rsa\/keys\/server.key/g' /etc/openvpn/server.conf
	sed -i 's/dh dh2048.pem/dh \/etc\/openvpn\/dh4096.pem/g' /etc/openvpn/server.conf
	sed -i 's/tls-auth ta.key/tls-auth \/etc\/openvpn\/easy-rsa\/keys\/ta.key/g' /etc/openvpn/server.conf
	
	if [ $(cat /etc/openvpn/server.conf | grep -c 'auth SHA512') -eq 1 ]
	then
		echo auth SHA512 >> /etc/openvpn/server.conf
	fi
	if [ $(cat /etc/openvpn/server.conf | grep -c 'echo tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384') -eq 1 ]
	then
		echo tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-256-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA:TLS-DHE-RSA-WITH-AES-128-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-128-CBC-SHA >> /etc/openvpn/server.conf
	fi
	
	sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
	sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/g' /etc/openvpn/server.conf
	sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/g' /etc/openvpn/server.conf
	
	systemctl enable openvpn@server.service
	systemctl start openvpn@server.service

}

conf_iptable() {

	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
	echo 'net.ipv4.ip_forward=1' | tee -a /etc/sysctl.d/99-sysctl.conf
	sysctl -p
	dpkg-reconfigure iptables-persistent

}

client() {
	
	cd /etc/openvpn/easy-rsa/
	
	source ./vars
	./build-key $client_name
	
	cd /etc/openvpn/easy-rsa/keys
	mkdir -p $client_name
	mv $client_name.crt $client_name/
	mv $client_name.key $client_name/
	cp ca.crt $client_name/
	cp ta.key $client_name/
	cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /etc/openvpn/easy-rsa/keys/$client_name/$client_name.ovpn
	
	sed -i "s/my-server-1/$IP/g" $client_name/$client_name.ovpn
	sed -i "s/cert client.crt/cert $client_name.crt/g" $client_name/$client_name.ovpn
	sed -i "s/key client.key/key $client_name.key/g" $client_name/$client_name.ovpn
	
	if [ $(cat /etc/openvpn/easy-rsa/keys/$client_name/$client_name.ovpn | grep -c 'auth SHA512') -eq 1 ]
	then
		echo auth SHA512 >> /etc/openvpn/easy-rsa/keys/$client_name/$client_name.ovpn
	fi
	tar czf $client_name.tar.gz $client_name
	cp $client_name.tar.gz /var/www/html/
}


echo "1. Setup OpenVPN Server"
echo "2. Setup Client files"
echo -e "\nDefault Choice is 1 (If server is not setup) + 2."


if [ -z $1 ]; then
	read choice
fi

if [ -z $choice ]; then
	choice="$1"
fi

IP=$(curl ifconfig.me/ip -s)

case $choice in
1) 
installations
server
conf_iptable
;;
2)
echo "Enter name of your client files. (Default: client7)"
read client_name
if [ -z $client_name ]
then
	client_name='client7'
fi
if [ ! -d /etc/openvpn/easy-rsa/keys/$client_name ]
then
	client
fi

clear
echo -e "You can download your client side files from this address \n http://$IP/$client_name.tar.gz"
;;
*)
if [ ! -e /etc/openvpn/easy-rsa/keys/ca.crt ]
then
		installations
		server
		conf_iptable
fi

echo "Enter name of your client files. (Default: client7)"
read client_name
if [ -z $client_name ]
then
	client_name='client7'
fi
if [ ! -d /etc/openvpn/easy-rsa/keys/$client_name ]
then
	client
fi

clear
echo -e "You can download your client side files from this address \n http://$IP/$client_name.tar.gz"
;;
esac
