FROM ubuntu:24.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apt-cacher-ng \
      ca-certificates \
      wget \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3142
VOLUME ["/var/cache/apt-cacher-ng", "/var/log/apt-cacher-ng"]

HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:3142/acng-report.html || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
