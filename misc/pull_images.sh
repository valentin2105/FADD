## Wordpress
#wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
wget https://en-ca.wordpress.org/wordpress-4.5.3-en_US.tar.gz -O /tmp/wordpress.tar.gz
## Joomla
#wget https://github.com/joomla/joomla-cms/releases/download/3.6.2/Joomla_3.6.2-Stable-Full_Package.zip -O /tmp/joomla.zip

## Drupal
wget https://ftp.drupal.org/files/projects/drupal-8.2.1.tar.gz -O /tmp/drupal.tar.gz

## Docker
docker pull php:7.0.9-fpm
docker pull nginx:latest
docker pull mariadb:latest
docker pull ghost:latest
docker pull quay.io/letsencrypt/letsencrypt:latest

## More images
#docker pull mquandalle/wekan:latest
#docker pull mongo:latest
