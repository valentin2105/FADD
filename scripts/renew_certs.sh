acmePath=/srv/acme/challenges
docker run -it --rm --name letsencrypt -v "/etc/letsencrypt:/etc/letsencrypt" -v "$acmePath:$acmePath" -v "/var/lib/letsencrypt:/var/lib/letsencrypt" quay.io/letsencrypt/letsencrypt renew -n --webroot --webroot-path $acmePath  -m expiry@ouvrard.it
