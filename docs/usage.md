# Usage

## Image

Built from `ubuntu:24.04`. A build stage rebuilds the distribution
`apt-cacher-ng` source package with `apt-cacher-ng.patch` (Tim Woodall's
per-URL download serialization fix for the concurrency race,
[Debian #1022043](https://bugs.debian.org/1022043) / Ubuntu #1983856 —
unmerged upstream, acng is unmaintained); the runtime stage installs the
resulting `.deb`. Without the patch, concurrent requests for the same volatile
index file race on the cache temp file and leave a corrupt `InRelease` that
fails GPG verification (`BADSIG`). The package's `SupportDir` mirror lists are
retained, so mounted configs using the stock `Remap-*` rules resolve out of the
box. The service runs in the foreground as the unprivileged `apt-cacher-ng`
user.

If a future Ubuntu `apt-cacher-ng` source no longer matches the patch context,
the build fails at `quilt push` rather than silently shipping unpatched — bump
or drop the patch then.

Tags:

- `latest` — head of `main`
- `vX.Y.Z` — git tag
- `sha-<commit>` — every pushed commit

## Ports and volumes

| Path | Purpose |
| --- | --- |
| `3142/tcp` | proxy + report page (`/acng-report.html`) |
| `/etc/apt-cacher-ng` | config directory (`acng.conf`) |
| `/var/cache/apt-cacher-ng` | on-disk package cache |
| `/var/log/apt-cacher-ng` | access/error logs |

The entrypoint creates and chowns the cache, log, and `/run/apt-cacher-ng`
socket directories to the service user on start, so root-owned bind mounts work
without extra setup.

## Configuration

Mount an `acng.conf` to override defaults:

```sh
docker run -d --name apt-cacher-ng -p 3142:3142 \
  -v /etc/finf/apt-cacher-ng:/etc/apt-cacher-ng \
  -v /var/cache/apt-cacher-ng:/var/cache/apt-cacher-ng \
  -v /var/log/apt-cacher-ng:/var/log/apt-cacher-ng \
  anarkiwi/apt-cacher-ng:latest
```

Point clients at it, e.g. `/etc/apt/apt.conf.d/00proxy`:

```
Acquire::http::Proxy "http://<host>:3142";
```

## Healthcheck

The image ships a `HEALTHCHECK` that fetches `/acng-report.html`; the container
reports `unhealthy` if the daemon stops answering.

## CI / publish

`.github/workflows/build.yml` builds an amd64 image, runs `test/smoke.sh`
(starts the container, checks the report page, proxies a real archive fetch, and
asserts it was cached), then on pushes to `main` and tags builds and pushes a
multi-arch (`amd64`, `arm64`) image to Docker Hub using the `DOCKER_USERNAME` and
`DOCKER_TOKEN` repository secrets. Dependabot tracks the base image and Actions.
