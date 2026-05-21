# ── Build ─────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ── Nginx ─────────────────────────────
FROM nginx:1.25-alpine

COPY --from=builder /app/dist /usr/share/nginx/html

# Configuración completa de Nginx con proxy inverso (inline)
RUN printf 'server {\n\
    listen 80;\n\
    server_name plagavision.djrbweb.com;\n\
\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    access_log /var/log/nginx/access.log;\n\
    error_log /var/log/nginx/error.log;\n\
\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
\n\
    location /api/ {\n\
        proxy_pass http://api.plagavision.djrbweb.com:5000/api/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_connect_timeout 300s;\n\
        proxy_send_timeout 300s;\n\
        proxy_read_timeout 300s;\n\
        \n\
        add_header Access-Control-Allow-Origin $http_origin always;\n\
        add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS" always;\n\
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;\n\
        \n\
        if ($request_method = "OPTIONS") {\n\
            add_header Access-Control-Allow-Origin $http_origin always;\n\
            add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS" always;\n\
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;\n\
            add_header Access-Control-Max-Age 3600;\n\
            add_header Content-Length 0;\n\
            return 204;\n\
        }\n\
    }\n\
\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]