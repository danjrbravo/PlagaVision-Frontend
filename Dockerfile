# ── Build ─────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ── Nginx con Proxy ─────────────────────────────
FROM nginx:1.25-alpine

COPY --from=builder /app/dist /usr/share/nginx/html

# Configuración de Nginx CON PROXY al backend
RUN printf 'server {\n\
    listen 80;\n\
    server_name plagavision.djrbweb.com;\n\
\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    # Proxy para API - Redirige /api al backend\n\
    location /api/ {\n\
        proxy_pass http://api.plagavision.djrbweb.com:5000/api/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Upgrade $http_upgrade;\n\
        proxy_set_header Connection "upgrade";\n\
        proxy_set_header Host api.plagavision.djrbweb.com;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_read_timeout 300s;\n\
        proxy_connect_timeout 75s;\n\
        \n\
        # Manejar CORS\n\
        add_header Access-Control-Allow-Origin * always;\n\
        add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS" always;\n\
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;\n\
        \n\
        if ($request_method = "OPTIONS") {\n\
            add_header Access-Control-Allow-Origin *;\n\
            add_header Access-Control-Allow-Methods "GET, POST, DELETE, OPTIONS";\n\
            add_header Access-Control-Allow-Headers "Content-Type, Authorization";\n\
            add_header Content-Length 0;\n\
            add_header Content-Type text/plain;\n\
            return 204;\n\
        }\n\
    }\n\
\n\
    # React Router - Manejar rutas\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
\n\
    # Cache para archivos estáticos\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
\n\
    # No cache para HTML\n\
    location ~* \\.html$ {\n\
        expires -1;\n\
        add_header Cache-Control "no-cache, no-store, must-revalidate";\n\
    }\n\
\n\
    # Compresión gzip\n\
    gzip on;\n\
    gzip_vary on;\n\
    gzip_min_length 1024;\n\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost || exit 1

CMD ["nginx", "-g", "daemon off;"]