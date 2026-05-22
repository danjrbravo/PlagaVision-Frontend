#!/bin/sh
set -e

# Sustituir el placeholder con la variable de entorno real
sed -i "s|BACKEND_URL_PLACEHOLDER|${BACKEND_URL}|g" /etc/nginx/conf.d/default.conf

echo ">>> Proxy configurado hacia: ${BACKEND_URL}"
cat /etc/nginx/conf.d/default.conf | grep proxy_pass

exec nginx -g "daemon off;"