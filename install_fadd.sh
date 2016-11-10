#! /bin/bash

if [[ "$1" != "--upgrade" ]]; then
	apt-get install -y apt-transport-https jq ca-certificates python-pip pwgen dnsutils wget unzip
fi

############################################################################
## This script is a fast-way to deploy FADD on a clean Debian jessie server.
############################################################################
# CHECK THESE VALUES :
############################################################################
### User Vars
configPath=$(echo $PWD/config.json)
faddPath=$(jq -r .faddPath $configPath)
installPath=$(jq -r .installPath $configPath)
logsPath=$(jq -r .logsPath $configPath)
pubIP=$(jq -r .pubIP $configPath)
distrib=$(jq -r .distrib $configPath)
acmeDomain=$(jq -r .acmeDomain $configPath)
acmePath=$(jq -r .acmePath $configPath)
adminMail=$(jq -r .adminMail $configPath)

############################################################################

if [[ "$1" != "--upgrade" ]]; then
	### Let's install requirements
	tput bold
	echo "Lets install Docker..."
	tput sgr0
	echo ""
	$faddPath/misc/install_docker.sh $distrib
fi

if [ "$faddPath" != "$installPath" ]; then
	### Let's copy scripts
	cp -r $faddPath/scripts $installPath
	cp -r $faddPath/www $installPath
	cp -r $faddPath/nginx $installPath
fi

### /usr/loca/bin symlinks
tput bold
echo "Create scripts symlinks..."
tput sgr0
echo ""
ln -s $installPath/scripts/add_stack.sh /usr/local/bin/add_stack
ln -s $installPath/scripts/delete_stack.sh /usr/local/bin/delete_stack
ln -s $installPath/scripts/renew_certs.sh /usr/local/bin/renew_certs

### Change user vars in scripts:
tput bold
echo "Change user variables..."
tput sgr0
echo ""
mkdir -p $acmePath
mkdir -p $logsPath

sed -i -- s/10.1.1.1/$pubIP/g $installPath/scripts/add_stack.sh
sed -i -- s+/srv/www+$installPath/www+g $installPath/scripts/add_stack.sh
sed -i -- s+/srv/scripts+$installPath/scripts+g $installPath/scripts/add_stack.sh
sed -i -- s+contact@example.com+$adminMail+g $installPath/scripts/add_stack.sh
sed -i -- s+/path/to/acme+$acmePath+g $installPath/scripts/add_domain.sh
sed -i -- s+/path/to/nginx+$installPath/nginx+g $installPath/scripts/add_domain.sh
sed -i -- s+/path/to/logs+$logsPath+g $installPath/scripts/add_domain.sh
sed -i -- s+/path/to/logs+$logsPath+g $installPath/scripts/add_stack.sh
sed -i -- s+/path/to/acme+$acmePath+g $installPath/scripts/renew_certs.sh
sed -i -- s+contact@example.com+$adminMail+g $installPath/scripts/renew_certs.sh
sed -i -- s+/srv+$installPath+g $installPath/scripts/delete_stack.sh


### Configure Nginx
sed -i -- s+/path/to/acme+$acmePath+g $installPath/nginx/docker-compose.yml
sed -i -- s+tls.example.com+$acmeDomain+g $installPath/nginx/conf-included/acme.conf
mv $installPath/nginx/sites-enabled/tls.example.com $installPath/nginx/sites-enabled/$acmeDomain
sed -i -- s+tls.example.com+$acmeDomain+g $installPath/nginx/sites-enabled/$acmeDomain
sed -i -- s+/path/to/acme+$acmePath+g $installPath/nginx/sites-enabled/$acmeDomain


if [[ "$1" != "--upgrade" ]]; then
	### Download images
	tput bold
	echo "Download latest images..."
	tput sgr0
	echo ""
	$faddPath/misc/pull_images.sh

	# Wordpress
	tar -zxf /tmp/wordpress.tar.gz -C $installPath/www/base/wordpress/
	mv $installPath/www/base/wordpress/wordpress $installPath/www/base/wordpress/www
	mv $installPath/www/base/wordpress/wp-config.php $installPath/www/base/wordpress/www

	# Drupal 8.2.1
	tar -zxf /tmp/drupal* -C $installPath/www/base/drupal/
	mv $installPath/www/base/drupal/drupal-8.2.1 $installPath/www/base/drupal/www

	# Joomla
	unzip /tmp/joomla.zip -d $installPath/www/base/joomla/www/ > /dev/null

	### Build latest PHP-FPM image
	tput bold
	echo "Build PHP-Fpm image..."
	tput sgr0
	echo ""
	docker build -t php-fpm:7.0.9 $installPath/www/base/build/php-fpm/

fi
### Launch Nginx
tput bold
echo "Launch Nginx..."
tput sgr0
echo ""
docker-compose -f $installPath/nginx/docker-compose.yml up -d

### Ready !
#
echo ""
tput bold
echo "F.A.D.D is now ready to use."
echo ""
tput sgr0
echo "You can add a stack with $installPath/scripts/add_stack.sh"
echo ""
$installPath/scripts/add_stack.sh -h
