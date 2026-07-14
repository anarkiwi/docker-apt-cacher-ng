#!/bin/bash
# End-to-end check: start the image, confirm the daemon serves its report page,
# then proxy a real archive fetch and confirm it lands in the on-disk cache.
# Checks run inside the container (wget is present) so they don't depend on
# host port publishing.
set -euo pipefail

IMAGE="${1:?usage: smoke.sh IMAGE}"
NAME="acng-smoke-$$"

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$NAME" "$IMAGE" >/dev/null

for i in $(seq 1 30); do
    if docker exec "$NAME" wget -q -O /dev/null http://localhost:3142/acng-report.html; then
        break
    fi
    if [ "$i" = 30 ]; then
        echo "apt-cacher-ng did not become ready" >&2
        docker logs "$NAME" >&2
        exit 1
    fi
    sleep 1
done

docker exec "$NAME" sh -eu -c '
    URL=http://localhost:3142/ubuntu/dists/noble/Release
    wget -q -O /dev/null "$URL"
    wget -q -O /dev/null "$URL"
    find /var/cache/apt-cacher-ng -name Release | grep -q . || {
        echo "fetched file was not cached on disk" >&2
        exit 1
    }
'

echo "OK: apt-cacher-ng served its report page and cached a proxied fetch"
