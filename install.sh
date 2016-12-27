#!/usr/bin/env bash

clear
echo "::: Start Configuration"

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

echo "::: Update the system"
if [[ $(command -v apt-get) ]]; then
	#Update and upgrade the distribution
	apt-get update && apt-get -y upgrade
	#install git
	echo "::: Install GIT"
	apt-get install -y build-essential git
	#what is my distrib ?
	distrib=$(lsb_release --codename | cut -f2)
else
  echo "OS distribution not supported"
  exit
fi

#trouveIp debian Jessie	
#[[ $(ip addr | grep enp0s25) != '' ]] && ip addr show dev enp0s25 | sed -n -r 's@.*inet (.*)/.*brd.*@\1@p' || ip addr show dev eth0 | sed -n -r 's@.*inet (.*)/.*brd.*@\1@p'
#Sinon
# myIP=$(ifconfig $(netstat -rn | grep -E "^default|^0.0.0.0" | head -1 | awk '{print $NF}') | grep 'inet ' | awk '{print $2}' | grep -Eo '([0-9]*\.){3}[0-9]*')

myIP=$(ifconfig $(netstat -rn | grep -E "^default|^0.0.0.0" | head -1 | awk '{print $NF}') | grep 'inet ' | awk '{print $2}' | grep -Eo '([0-9]*\.){3}[0-9]*')

#Get last version of FADD
echo "::: Get last version of FADD"
git clone https://github.com/valentin2105/FADD.git /tmp/FADD

#
until [  "$response" = "yes" ]
do 
	echo "What is the path where you want to manage your stacks ? By defaut the path is /srv"
	read installPath

	echo "What is your server public IP or cloud local IP ? By defaut the IP is $myIP"
	read pubIP

	while [ -z $acmeDomain ]
	do
	echo "What is your dedicated domain name pointed on your server ? (tls.example.com)"
		read acmeDomain
	done

	echo "Where do you want to put .well_knows challenge (TLS) ? By defaut the path is /srv/certs/challenges"
	read acmePath

	while [ -z $adminMail ]
	do
		echo "What is you adress mail ? (for certs generation)"
		read adminMail
	done

	if [ -z "$installPath" ]; then
		installPath="/srv"
	fi

	if [ -z "$pubIP" ]; then
		pubIP=$myIP
	fi

	if [ -z "$acmePath" ]; then
		acmePath="/srv/certs/challenges"
	fi

	echo ""
	echo ""
	echo "::: FADD Configuration is:"
	echo "Install path: $installPath"
	echo "IP server: $pubIP"
	echo "Your domain is: $acmeDomain"
	echo "Path to well_knows: $acmePath"
	echo "Your email: $adminMail"
	echo ""
	echo "Is it OK ? yes/no"
	read response
done

sed -i -- s+/opt/FADD+/tmp/FADD/+g /tmp/FADD/config.json
sed -i -- s+/srv+$installPath+g /tmp/FADD/config.json
sed -i -- s/10.1.1.1/$pubIP/g /tmp/FADD/config.json
sed -i -- s+jessie+$distrib+g /tmp/FADD/config.json
sed -i -- s+tls.example.com+$acmeDomain+g /tmp/FADD/config.json
sed -i -- s+/srv/certs/challenge+$acmePath+g /tmp/FADD/config.json
sed -i -- s+contact@example.com+$adminMail+g /tmp/FADD/config.json

echo "::: Start Install"
chmod +x /tmp/FADD/install_fadd.sh
./tmp/FADD/install_fadd.sh
