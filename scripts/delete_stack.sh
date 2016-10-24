#! /bin/bash
installPath=/srv
stack=$1
certToo=$2

if [ -z "$1" ]; then
  echo "Please give a Stack name"
  exit 1
else
  read -p "Are you sure to delete $1 ? [y/N]  " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    docker-compose -f $installPath/www/$1/docker-compose.yml down
    rm $installPath/nginx/sites-enabled/$1
    rm -r $installPath/www/$1
    if [ "$2" == "--all" ]; then
      rm -r /etc/letsencrypt/live/$1
      rm -r /etc/letsencrypt/archive/$1
      rm /etc/letsencrypt/renewal/"$1".conf
    fi
  else
    exit 0
  fi
fi
