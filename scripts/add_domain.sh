#! /bin/bash

nginx_name=nginx_front_nginx_1
path=/path/to/acme
nginxPath=/path/to/nginx
logsPath=/path/to/logs
# Catch Args
##################################################################
while test $# -gt 0; do
        case "$1" in
                -h|--help)
			echo " "
                        echo "Add_Domain.sh -- Create a new Domain deployment"
                        echo " "
                        echo "add_domain.sh [arguments]"
                        echo " "
                        echo "options:"
                        echo "-h, --help                show brief help"
                        echo "--security=YES/NO         reverse-proxy to https/http"
			echo "--backend=IP:PORT         specify a ip to redirect"
			echo "--domain=DOMAIN           specify a port to redirect"
                        echo "--email=EMAIL-ADDRESS     specify a contact for Lets encrypt"
                        exit 0
                        ;;

                --security*)
                        export security=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                --backend*)
                        export backend=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
		--domain*)
			export domain=`echo $1 | sed -e 's/^[^=]*=//g'`
			shift
			;;
                --email*)
			export mail=`echo $1 | sed -e 's/^[^=]*=//g'`
			shift
			;;
                *)
                        break
			exit 1
                        ;;
        esac
done
echo "Creating domain $domain ..." 2>&1 | tee -a $logsPath
## Gen certs using tls.example.com
docker run -it --rm --name letsencrypt -v "/etc/letsencrypt:/etc/letsencrypt" -v "$path":"$path" -v "/var/lib/letsencrypt:/var/lib/letsencrypt" quay.io/letsencrypt/letsencrypt certonly -n --webroot --webroot-path $path --agree-tos --rsa-key-size 4096 -d $domain -m $mail 2>&1 | tee -a $logsPath
verifCerts=$(echo $?)

## Check IF Certs are presents
if [ $verifCerts -eq 1 ]; then
exit 1
fi

## Deploy Nginx configuration
if [ "$security" == "no" ] || [ "$security" == "NO" ] ; then
cat $nginxPath/example.com |sed s/example.com/$domain/g |sed s+127.0.0.1+$backend+g  > $nginxPath/sites-enabled/$domain
fi
if [ "$security" == "yes" ] || [ "$security" == "YES" ] ; then
cat $nginxPath/example.com |sed s/example.com/$domain/g |sed s+http://127.0.0.1+https://$backend+g  > $nginxPath/sites-enabled/$domain
fi

## Reload Nginx configuration
docker kill -s HUP $nginx_name > /dev/null
verifNginx=$(echo $?)

## Check IF Nginx clean reload
if [ $verifNginx -eq 1 ]; then
exit 1
echo "Problem reloading Nginx" 2>&1 | tee -a $logsPath
fi

echo "Nginx reload sucess" 2>&1 | tee -a $logsPath
exit 0
