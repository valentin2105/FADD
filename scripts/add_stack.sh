#!/usr/bin/env bash

## Docker auto-Deployement with Nginx Let's Encrypt support.
## You have too point DNS of your domain to your server, Launch the nginx container
## And finally, you can deploy stack like this :
## $ add_stack.sh --image=wordpress --domain=blog.example.com -e 8111

## Script configuration
##################################################################
pubIP=10.1.1.1
adminMail=contact@example.com
faddPath=/srv/www
scriptsPath=/srv/scripts
dockerPath=/usr/bin
composePath=/usr/local/bin
logsPath=/path/to/logs

## Catch Args
##################################################################
while test $# -gt 0; do
	case "$1" in
        	-h|--help)
			echo " "
                        echo "Add_Stack.sh -- Create a new Docker deployment"
                        echo " "
                        echo "add_stack.sh [arguments]"
                        echo " "
                        echo "options:"
                        echo "-h, --help                show brief help"
                        echo "-i, --image=IMAGE         specify an image to use"
			echo "-d, --domain=DOMAIN       specify a domain to use"
			echo "-e, --expose=PORT         specify a port to expose the service"
                        exit 0
                        ;;
                -i)
                        shift
                        if test $# -gt 0; then
                                export stackType=$1
                        else
                                echo "no image specified"
                                exit 1
                        fi
                        shift
                        ;;
                --image*)
                        export stackType=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
		-d)
                        shift
                        if test $# -gt 0; then
                                export siteName=$1
                        else
                                echo "no domain specified"
                                exit 1
                        fi
                        shift
                        ;;
                --domain*)
                        export siteName=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
		-e)
			shift
			if test $# -gt 0; then
				export portWeb=$1
			else
				echo "no port specified"
				exit 1
			fi
			shift
			;;
		--expose*)
			export portWeb=`echo $1 | sed -e 's/^[^=]*=//g'`
			shift
			;;
                *)
                        break
			exit 1
                        ;;
        esac
done

## Make some checks
##################################################################
#set -o errexit
#set -o nounset

### Check args
### Colors
CSI="\033["
CGREEN="${CSI}1;32m"
CRED="${CSI}1;31m"
CEND="${CSI}0m"
echo
logsFile=$(echo "$logsPath"/"$siteName".log)
echo "Let's create `tput bold`$siteName`tput sgr0`..."  | tee -a $logsFile
echo
if [ -z $siteName ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Have you forget a Domain for your stack ? Check --help"
  exit 1
fi
if [ -z $portWeb ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Have you forget a Port for your stack ? Check --help"
  exit 1
fi
if [ -z $stackType ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Have you forget an Image for your stack ? Check --help"
  exit 1
fi


### Check Dependencies
if [ ! -e $dockerPath/docker ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Docker is not present in $dockerPath" 2>&1 | tee -a $logsFile
	exit 1
fi
if [ ! -e $composePath/docker-compose ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Docker-compose is not present in /usr/local/bin" 2>&1 | tee -a $logsFile
	exit 1
fi
if [ ! -e /usr/bin/pwgen ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "Pwgen is not present in /usr/bin, please install pwgen" 2>&1 | tee -a $logsFile
	exit 1
fi
### Check if folder already exist
if [ -d $faddPath/$siteName ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "The stack $siteName already exist, delete it first." 2>&1 | tee -a $logsFile
	exit 1
fi

### Check DNS zone
siteNameDNS=$(nslookup $siteName | awk '/^Address: / { print $2 ; exit }')
if [ "$pubIP" != "$siteNameDNS" ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "The DNS of $siteName dont point on your server." 2>&1 | tee -a $logsFile
	exit 1
fi

### Check free TCP port
netstat -ltapunte |grep 'tcp' | grep $portWeb > /dev/null
checkPort=$(echo $?)
if [ $checkPort -eq 0 ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "The port $portWeb look like already using !" 2>&1 | tee -a $logsFile
	exit 1
fi

### Check Nginx Running
docker ps |grep "0.0.0.0:443" |grep nginx  > /dev/null
checkNginx=$(echo $?)
if [ $checkNginx -eq 1 ]; then
	echo -e "       Make some verifications        [${CRED}FAIL${CEND}]"
	echo
	echo "There is any Nginx instance running on your Docker host ?" 2>&1 | tee -a $logsFile
fi

echo -e "       Make some verifications        [${CGREEN}OK${CEND}]"
##################################################################
## Let's go
##################################################################
## Create Certs & Reverse-Proxy vhost to https
if [ "$stackType" == "ghost" ] || [ "$stackType" == "wekan" ] || [ "$stackType" == "rocketchat" ] ; then
	$scriptsPath/add_domain.sh --proto=http --domain=$siteName --backend="$pubIP":"$portWeb"  --email="$adminMail"
	checkAddDomain=$(echo $?)
else
	$scriptsPath/add_domain.sh --proto=https --domain=$siteName --backend="$pubIP":"$portWeb"  --email="$adminMail"
	checkAddDomain=$(echo $?)
fi

## Check IF Certs are presents
if [ ! -d /etc/letsencrypt/live/$siteName ]; then
  echo -e "       Generate stack certificates    [${CRED}FAIL${CEND}]"
	echo
	echo "Problem found with certs generation, Check DNS !" 2>&1 | tee -a $logsFile
	exit 1
fi
echo -e "       Generate stack certificates    [${CGREEN}OK${CEND}]"

if [ $checkAddDomain -eq 0 ]; then
echo -e "       Reload Nginx configuration     [${CGREEN}OK${CEND}]"
else
echo -e "       Reload Nginx configuration     [${CRED}FAIL${CEND}]"
fi

## Copy base install Wordpress
cp -r $faddPath/base/$stackType $faddPath/$siteName
checkCopy=$(echo $?)
if [ $checkCopy -eq 0 ]; then
echo -e "       Copy image default config      [${CGREEN}OK${CEND}]"
else
echo -e "       Copy image default config      [${CRED}FAIL${CEND}]"
fi
##################################################################
##################################################################
##################################################################
if  [ "$stackType" == "wordpress" ]; then
	## Let's generate a DB password
	wpDbPasswd=$(pwgen 16 1)

	## Change port, password and site_name to bind
  sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/nginx.conf
	sed -i -- s/aStr0NgPaSsw0rd/$wpDbPasswd/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/aStr0NgPaSsw0rd/$wpDbPasswd/g $faddPath/$siteName/www/wp-config.php

	## Grant good permissions
	chown www-data:www-data $faddPath/$siteName/www -R

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d wp_db  &>/dev/null 2>&1 | tee -a $logsFile
	## Sleep for waiting MySQL running
	sleep 10;
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d wp_fpm  &>/dev/null 2>&1 | tee -a $logsFile
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d wp_front  &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)

	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Wordpress is reachable at https://$siteName" 2>&1 | tee -a $logsFile
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "ghost" ]; then

	ghostDbPasswd=$(pwgen 16 1)
	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/aStr0NgPaSsw0rd/$ghostDbPasswd/g $faddPath/$siteName/docker-compose.yml

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d ghost_db  &>/dev/null 2>&1 | tee -a $logsFile
	## Sleep for waiting MySQL running
	sleep 15;
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d ghost_engine  &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)

	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Ghost is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "lemp" ]; then
	## Let's generate a DB password
  lempDbPasswd=$(pwgen 16 1)
	sed -i -- s/aStr0NgPaSsw0rd/$lempDbPasswd/g $faddPath/$siteName/docker-compose.yml

	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/nginx.conf

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your LEMP is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "wekan" ]; then
	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/localhost/$siteName/g  $faddPath/$siteName/docker-compose.yml

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Wekan is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "drupal" ]; then
	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/nginx.conf

	## Grant good permissions
	chown www-data:www-data $faddPath/$siteName/www -R

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Drupal is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "joomla" ]; then
	## Let's generate a DB password
  joomlaDbPasswd=$(pwgen 16 1)
	sed -i -- s/aStr0NgPaSsw0rd/$joomlaDbPasswd/g $faddPath/$siteName/docker-compose.yml

	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/nginx.conf

	## Grant good permissions
	chown www-data:www-data $faddPath/$siteName/www -R

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Joomla is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "piwik" ]; then
	## Let's generate a DB password
  piwikDbPasswd=$(pwgen 16 1)
	sed -i -- s/aStr0NgPaSsw0rd/$piwikDbPasswd/g $faddPath/$siteName/docker-compose.yml

	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml
	sed -i -- s/example.com/$siteName/g $faddPath/$siteName/nginx.conf

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your Piwik is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
##################################################################
if  [ "$stackType" == "rocketchat" ]; then

	## Change port and site_name to bind
	sed -i -- s/8100/$portWeb/g $faddPath/$siteName/docker-compose.yml

	## Launch the stack
	$composePath/docker-compose -f $faddPath/$siteName/docker-compose.yml up -d   &>/dev/null 2>&1 | tee -a $logsFile
	sleep 5
	checkLaunch=$(echo $?)
	if [ $checkLaunch -eq 0 ]; then
		echo -e "       Launch the stack               [${CGREEN}OK${CEND}]"
		echo
		echo "Your RocketChat is reachable at https://$siteName"
		echo
		exit 0
  else
		echo -e "       Launch the stack               [${CRED}FAIL${CEND}]"
		exit 1
	fi
fi
#######
