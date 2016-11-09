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
                        echo "--proto=http/https         reverse-proxy to https/http"
			echo "--backend=IP:PORT         specify a ip to redirect"
			echo "--domain=DOMAIN           specify a port to redirect"
                        echo "--email=EMAIL-ADDRESS     specify a contact for Lets encrypt"
                        exit 0
                        ;;

                --proto*)
                        export proto=`echo $1 | sed -e 's/^[^=]*=//g'`
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
logsFile=$(echo "$logsPath"/"$domain".log)
echo "Creating domain $domain ..." | tee -a $logsFile  &>/dev/null
## Gen certs using tls.example.com
docker run -it --rm --name letsencrypt -v "/etc/letsencrypt:/etc/letsencrypt" -v "$path":"$path" -v "/var/lib/letsencrypt:/var/lib/letsencrypt" quay.io/letsencrypt/letsencrypt certonly -n --webroot --webroot-path $path --agree-tos --rsa-key-size 4096 -d $domain -m $mail | tee -a $logsFile  &>/dev/null
verifCerts=$(echo $?)

## Check IF Certs are presents
if [ $verifCerts -eq 1 ]; then
exit 1
fi

## Deploy Nginx configuration
if [ "$proto" == "HTTP" ] || [ "$proto" == "http" ] ; then
cat $nginxPath/example.com |sed s/example.com/$domain/g |sed s+127.0.0.1+$backend+g  > $nginxPath/sites-enabled/$domain
fi
if [ "$proto" == "HTTPS" ] || [ "$proto" == "https" ] ; then
cat $nginxPath/example.com |sed s/example.com/$domain/g |sed s+http://127.0.0.1+https://$backend+g  > $nginxPath/sites-enabled/$domain
fi

## Reload Nginx configuration
docker kill -s HUP $nginx_name > /dev/null
verifNginx=$(echo $?)

## Check IF Nginx clean reload
if [ $verifNginx -eq 1 ]; then
exit 1
echo "Problem reloading Nginx" | tee -a $logsFile  &>/dev/null
fi

echo "Nginx reload sucess" | tee -a $logsFile  &>/dev/null
exit 0
