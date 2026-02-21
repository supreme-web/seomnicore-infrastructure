# =========================
# x-index.com (HTTP -> HTTPS)
# =========================
server {
  listen 80;
  listen [::]:80;

  server_name x-index.com www.x-index.com;

  return 301 https://$host$request_uri;
}

# =========================
# x-index.com (HTTPS reverse proxy -> Next.js / landing)
# =========================
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;

  server_name x-index.com www.x-index.com;

  ssl_certificate     /etc/letsencrypt/live/x-index.com-0001/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/x-index.com-0001/privkey.pem;

  server_tokens off;

  location / {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;

    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
