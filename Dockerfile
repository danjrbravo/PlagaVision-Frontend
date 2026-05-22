# ── Build ─────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Asegúrate de que VITE_API_URL esté disponible durante el build
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

# También pasa otras variables si las necesitas
ARG VITE_APP_NAME
ENV VITE_APP_NAME=$VITE_APP_NAME
ARG VITE_APP_VERSION
ENV VITE_APP_VERSION=$VITE_APP_VERSION

# Verifica que la variable está presente (opcional, para debug)
RUN echo "Building with API URL: $VITE_API_URL"

RUN npm run build

# ── Nginx ─────────────────────────────
FROM nginx:1.25-alpine

# Instalar curl para healthchecks (opcional)
RUN apk add --no-cache curl

COPY --from=builder /app/dist /usr/share/nginx/html

# Configuración de nginx con proxy al backend
RUN printf 'server {\n\
    listen 80;\n\
    server_name plagavision.djrbweb.com;\n\
\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    # Manejo de rutas del frontend (SPA)\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
\n\
    # Proxy para API - IMPORTANTE: apunta al puerto correcto\n\
    location /api/ {\n\
        proxy_pass http://api.plagavision.djrbweb.com:5002/;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        proxy_connect_timeout 300s;\n\
        proxy_send_timeout 300s;\n\
        proxy_read_timeout 300s;\n\
    }\n\
\n\
    # Archivos estáticos con caché\n\
    location ~* \\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]