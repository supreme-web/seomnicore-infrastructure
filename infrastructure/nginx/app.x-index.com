server {

  listen 80;
  listen [::]:80;
  server_name app.x-index.com;

  server_tokens off;

  # ACME challenge (Let’s Encrypt) - NÃO redirecionar
  location ^~ /.well-known/acme-challenge/ {
    root /var/www/letsencrypt;
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
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name app.x-index.com;

  server_tokens off;

 ssl_certificate     /etc/letsencrypt/live/app.x-index.com-dedicado/fullchain.pem;
 ssl_certificate_key /etc/letsencrypt/live/app.x-index.com-dedicado/privkey.pem;

  # Segurança TLS (compatível e forte)
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:10m;
  ssl_session_tickets off;

  ssl_protocols TLSv1.2 TLSv1.3;

  # (Opcional forte) HSTS — só ative quando tiver certeza que HTTPS está 100%
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

  # Converte /api/ -> /api internamente (sem redirecionar o cliente)
  location = /api/ {
  rewrite ^ /api break;
}

  # Rate-limit e proxy para /api (sem barra)
  location ^~ /api {
  limit_req zone=api_limit burst=30 nodelay;

  proxy_pass http://172.17.0.1:3001;

  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;

  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
}

  # Cache para assets comuns (imagens, fontes, css/js fora do _next)
  # Cache para assets comuns (não necessariamente versionados por hash)
  location ~* \.(?:css|js|mjs|map|jpg|jpeg|png|gif|webp|avif|svg|ico|woff2?|ttf|otf|eot)$ {
  proxy_pass http://172.17.0.1:3001;

  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;

  expires 30d;
  add_header Cache-Control "public, max-age=2592000" always;

  access_log off;
}


  # Cache forte para assets versionados do Next.js
  location ^~ /_next/static/ {
  proxy_pass http://172.17.0.1:3001;

  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;

  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";

  expires 365d;
  add_header Cache-Control "public, max-age=31536000, immutable" always;

  access_log off;
}


  # ACME (não é necessário no 443, mas não atrapalha)
  location ^~ /.well-known/acme-challenge/ {
    root /var/www/letsencrypt;
    try_files $uri =404;
    allow all;
    access_log off;
    log_not_found off;
  }

  # PROXY para o seu NPM / app interno (AJUSTAREMOS NO PRÓXIMO PASSO)
location / {
  proxy_pass http://172.17.0.1:3001;

  # Headers corretos para Next.js
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto https;

  # HTTP 1.1 (necessário para websockets e keepalive)
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";

  # Timeouts estáveis
  proxy_connect_timeout 10s;
  proxy_send_timeout 60s;
  proxy_read_timeout 60s;

  # Buffers mais seguros
  proxy_buffering on;
  proxy_buffers 16 64k;
  proxy_buffer_size 64k;

  proxy_redirect off;

  # Segurança leve compatível com Next.js
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
}
