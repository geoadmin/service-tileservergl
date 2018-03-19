#!/bin/bash
set -e

mako-render --var "maputnik_root=${MAPUTNIK_ROOT}" /etc/nginx/nginx.conf.in > /etc/nginx/nginx.conf

# Always put this damn shit
exec "$@"
