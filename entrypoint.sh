#!/bin/sh
# Ensure the bind-mounted cache/log dirs are writable by the service user,
# then run apt-cacher-ng in the foreground as that user.
set -eu

for dir in /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /run/apt-cacher-ng; do
    mkdir -p "$dir"
    chown apt-cacher-ng:apt-cacher-ng "$dir"
done

exec setpriv --reuid apt-cacher-ng --regid apt-cacher-ng --init-groups \
    /usr/sbin/apt-cacher-ng -c /etc/apt-cacher-ng ForeGround=1 "$@"
