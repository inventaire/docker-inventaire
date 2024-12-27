#!/bin/sh
set -e

mkdir -p /tmp/nginx/tmp /tmp/nginx/resize/img/users /tmp/nginx/resize/img/groups /tmp/nginx/resize/img/entities /tmp/nginx/resize/img/remote /tmp/nginx/resize/img/assets /etc/nginx

# Declare which variable to replace by envsubst, otherwise anything starting with $ (ie. $uri, $host) will be replaced (by an empty string)
envsubst '$PROJECT_ROOT $DOMAIN_NAME' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

while :; do
  sleep 12h & wait $!;
  nginx -s reload;
done &

nginx -g 'daemon off;'
