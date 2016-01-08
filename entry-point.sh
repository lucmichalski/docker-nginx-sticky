#!/usr/bin/env bash

set -u
set -e

for f in /etc/secrets/* ; do
    if test -f "$f"; then
        export $(echo $(basename $f) | awk '{print toupper($0)}')="$(eval "echo \"`<$f`\"")"
    fi
done

sed -i '/include \/etc\/nginx\/conf.d/q' /etc/nginx/nginx.conf
echo '}' >> /etc/nginx/nginx.conf 

ENVUP=$(echo $ENVIRONMENT | awk '{print toupper($0)}')
cat <<- EOF > /etc/nginx/conf.d/server.conf

upstream backend {
    server $IRCAPI0_SERVICE_HOST:$IRCAPI0_SERVICE_PORT;
    server $IRCAPI1_SERVICE_HOST:$IRCAPI1_SERVICE_PORT;
    server $IRCAPI2_SERVICE_HOST:$IRCAPI2_SERVICE_PORT;

    #sticky cookie srv_id expires=1h;
}

server {
    listen       ${PORT:-8000} default_server;
    listen       [::]:${PORT:-8000} default_server;
    server_name  _;

    location / {
        proxy_pass https://backend;
        proxy_ssl_verify              off;
    }
}
EOF

exec "$@"
