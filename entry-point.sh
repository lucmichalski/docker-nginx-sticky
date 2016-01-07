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

cat <<- EOF > /etc/nginx/conf.d/server.conf

upstream backend {

EOF
M=$(($(env | grep -i ${ENVIRONMENT}_IRCAPI*_SERVICE_HOST | wc -l )+1))
X=0
while [ $X -le $M ]; do
cat <<- EOF >> /etc/nginx/conf.d/server.conf
    server ${ENVIRONMENT}_IRCAPI${X}_SERVICE_HOST:${ENVIRONMENT}_IRCAPI${X}_SERVICE_PORT;
EOF
X=$((X+1))
done;

cat <<- EOF >> /etc/nginx/conf.d/server.conf
    sticky cookie srv_id expires=1h;
}

server {
    listen       ${PORT:-8000} default_server;
    listen       [::]:${PORT:-8000} default_server;
    server_name  _;

    location / {
        proxy_pass http://backend;
    }
}
EOF

exec "$@"
