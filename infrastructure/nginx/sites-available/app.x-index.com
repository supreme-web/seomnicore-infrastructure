server {

  listen 80;
  listen [::]:80;
  server_name app.x-index.com;

  server_tokens off;

  # ACME challenge (Let’s Encrypt) - NÃO redirecionar
  location ^~ /.well-known/acme-challenge/ {
    root /data/letsencrypt-acme-challenge;
    try_files $uri =404;
    allow all;
    access_log off;
    log_not_found off;
  }

  
 # Redireciona TODO o resto para HTTPS (sem afetar ACME acima)
location / {
  return 301 https://$host$request_uri;
}

}
