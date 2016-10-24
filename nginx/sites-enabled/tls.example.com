server {
        allow all;
        server_name   tls.example.com; 
        listen 80;
        root /srv/letsencrypt.sh/challenges/;
        location / {
                allow all;
        }
        location /.well-known/acme-challenge/ {
                default_type "text/plain";
        }
}
