# apt-cacher-ng

Maintained [apt-cacher-ng](https://www.unix-ag.uni-kl.de/~bloch/acng/) caching
proxy on Ubuntu 24.04, published to Docker Hub as
[`anarkiwi/apt-cacher-ng`](https://hub.docker.com/r/anarkiwi/apt-cacher-ng).

```sh
docker run -d --name apt-cacher-ng -p 3142:3142 \
  -v /var/cache/apt-cacher-ng:/var/cache/apt-cacher-ng \
  anarkiwi/apt-cacher-ng:latest
```

Listens on `3142/tcp`. Config `/etc/apt-cacher-ng`, cache
`/var/cache/apt-cacher-ng`, logs `/var/log/apt-cacher-ng`.

See [docs/usage.md](docs/usage.md) for configuration, volumes, and the CI/publish
pipeline.
