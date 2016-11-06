# FADD (Fully Automated Docker Deployments)
![](http://i.imgur.com/AvRuVrn.png)
> F.A.D.D is a bunch of shell scripts that provide a easy way to deploy application stacks (based on Docker-Compose) secured over a multi-domain TLS reverse-proxy (Nginx) with Let's Encrypt auto-generation and virtual hosts auto-deployment.

### Features :
- Nginx TLS Reverse-proxy
- Automatic Let's Encrypt support
- SNI Multi-Domain support
- Multi-image deployment (Wordpress, LEMP, Ghost, Drupal ...)
- Automatic script for launch a deployment

### Scripts :
Easily install Docker and all requirements :
```
cd /opt 
git clone https://github.com/valentin2105/FADD.git 
cd /opt/FADD ; vim config.json # Configure FADD
./install_fadd.sh
```

There are some shell scripts to manage your Docker Host :
- `add_stack.sh` - Deploy an app stack and his Nginx TLS vhost.
- `add_domain.sh` - Deploy a Nginx TLS vhost to proxify a specified port.
- `delete_stack.sh` - Delete datas, certs & config of the app stack.
- `renew_certs.sh` - Renew all TLS certs presents on the host.

### Examples :
- Deploy All-in-one Wordpress :

`add_stack.sh --image=wordpress --domain=site01.example.com --expose=8101`

- Run a docker service an expose his port :

`docker run --name nginx -d -p 8080:80 nginx:latest`

`add_domain.sh --proto=http --ip=10.0.0.5 --port=8080`

### Requirements :
- Ubuntu (14.04 / 16.04) / Debian 8
- Python 2.7
- Docker 1.x
- Docker-compose
- curl, openssl, jq, wget, netstat ...

### Hub :
- Wordpress (Nginx/PHP7/MariaDB)
- Joomla (Nginx/PHP7/MariaDB)
- Drupal 8 (Nginx/PHP7/SQLite)
- LEMP (Nginx/PHP7/MariaDB) 
- Ghost (Nginx, Ghost JS)
- Wekan (Nginx, Wekan MeteorJS)

### Demo :

[![asciicast](https://asciinema.org/a/91585.png)](https://asciinema.org/a/91585)

## https://fadd.opsnotice.xyz
