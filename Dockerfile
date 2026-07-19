# Stage 1: rebuild the apt-cacher-ng .deb from the Ubuntu source with the
# upstream concurrency fix. Stock acng 3.7.4 has a race (Debian #1022043 /
# Ubuntu #1983856): concurrent requests for the same volatile index file
# collide on the cache temp file ("File exists"), leaving a half-written
# InRelease that fails GPG (BADSIG). Tim Woodall's patch serializes downloads
# per URL. It is unmerged upstream (acng is unmaintained), so it is vendored
# here as apt-cacher-ng.patch and built into the package. The patched logic
# lives in libsupacng.so, so the whole package is rebuilt (not just the thin
# apt-cacher-ng frontend binary).
FROM ubuntu:24.04 AS build
ENV DEBIAN_FRONTEND=noninteractive
COPY apt-cacher-ng.patch /tmp/apt-cacher-ng.patch
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources \
 && apt-get update \
 && apt-get install -y --no-install-recommends build-essential dpkg-dev quilt \
 && apt-get build-dep -y apt-cacher-ng
WORKDIR /build
RUN apt-get source apt-cacher-ng \
 && cd apt-cacher-ng-*/ \
 && export QUILT_PATCHES=debian/patches \
 && quilt import /tmp/apt-cacher-ng.patch \
 && quilt push -a \
 && DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" dpkg-buildpackage -b -us -uc \
 && mkdir -p /out \
 && cp /build/apt-cacher-ng_*.deb /out/

# Stage 2: runtime. Install the patched package (apt resolves its runtime deps),
# plus the healthcheck/fetch tooling.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=build /out/apt-cacher-ng_*.deb /tmp/

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      /tmp/apt-cacher-ng_*.deb \
      ca-certificates \
      wget \
 && rm -rf /var/lib/apt/lists/* /tmp/*.deb

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3142
VOLUME ["/var/cache/apt-cacher-ng", "/var/log/apt-cacher-ng"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:3142/acng-report.html || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
