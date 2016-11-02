server {
        allow all;
        server_name   tls.example.com;
        listen 80;
        root /path/to/acme;
        location / {
                allow all;
        }
        location /.well-known/acme-challenge/ {
                default_type "text/plain";
        }
}
