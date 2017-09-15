# Docker base image to run microservice with a data volume
[![Docker Automated Build](https://img.shields.io/docker/automated/powerman/alpine-runit-volume.svg)](https://github.com/powerman/alpine-runit-volume)
[![Docker Build Status](https://img.shields.io/docker/build/powerman/alpine-runit-volume.svg)](https://hub.docker.com/r/powerman/alpine-runit-volume/)

This base docker image is designed to:

- Correctly run microservice with multiple processes:
  - Clean up zombie processes.
  - Graceful shutdown on `docker stop`.
  - Easy to run extra services (syslog, cron, ssh, etc.).
  - On essential service crash you can either restart it or stop
    container.
- Handle persistent storage permissions and migrations:
  - Microservice can run as non-root account "app".
  - Account "app" is the owner of attached data volume directory.
    - In case of using bind mount this account will have same UID/GID as
      mounted directory - so you don't get files with unusual ownership in
      this directory as result of running container.
    - In case of using new volume it ownership will be changed to random
      UID/GID (to better isolate container's data and processes). When
      container will start next time using same volume it'll use same
      UID/GID.
- Be small and secure, thanks to Alpine Linux.

## Usage

```Dockerfile
FROM powerman/alpine-runit-volume

# Add your files (/app dir is just an example):
COPY . /app

# Either setup your runit services to run in /etc/service/:
RUN ln -nsf /app/service/* /etc/service/
# or run your microservice as PID1 (without runit):
CMD ["/app/my-pid-1-app"]

# [OPTIONAL] Change default directory with volume (/data):
ENV VOLUME_DIR=/app/data

# [OPTIONAL] Use cron service and setup /app/crontab for user "app":
RUN set -ex -o pipefail; \
    ln -s /etc/sv/dcron /etc/service/cron; \
    install -m 0600 /app/crontab /etc/crontabs/app; \
    echo app >> /etc/crontabs/cron.update
```

These environment variables can be provided when starting container:

- `APP_UID`, `APP_GID`: numeric UID/GID to be used for "app" account and
  to set ownership for root directory of attached volume.
  - If `APP_UID=0` then both will be ignored.
  - I recommend to use values between 1000 and 60000 to avoid conflicts
    with existing accounts.
- `VOLUME_DIR`: directory with data volume (`/data` by default)

To run your command using "app" account: `chpst -u app …` (use in your
service's `./run` and `./finish` scripts).

To gracefully shutdown container on essential service exit/crash add to
that service's `./finish` script (run as root): `sv d /etc/sv/runsvdir`

By default, your service's STDOUT/STDERR will be sent to docker logs
(using "stdout" log stream for both). To redirect your service's STDOUT to
syslog you can pipe output of your service to `logger` tool using this
`./log/run` script for your service:

```sh
#!/bin/sh
sv start syslog >/dev/null 2>&1 || exit 1
exec chpst -u app logger
```

Syslog service is enabled by default (unless you'll run your app as PID 1)
and save logs into `/var/log/`. You can configure maximum log size and
amount of old rotated log files (10 x 1MB files by default) and other
features (duplicating selected log records to docker log, sending to
network syslog by UDP, etc.) using
[/var/log/config](http://smarden.org/runit/svlogd.8.html#sect6).

If you enable `/etc/sv/dcron` service you can setup cron tasks using this
[crontab format](https://github.com/dubiousjim/dcron/blob/master/crontab.markdown).

## How it works

When container starts `setup-volume` will be executed as `ENTRYPOINT` to:

- create user account "app"
  - use UID/GID provided in environment variables `APP_UID`/`APP_GID`
    if `APP_UID` is greater than 0
  - use UID/GID of current owner of root directory of data volume,
    if owner's UID is greater than 0
  - generate random UID/GID between 10000 and 42767 (inclusive)
- ensure root directory of data volume belongs to user "app"
  - use path for data volume provided in environment variable `VOLUME_DIR`
    or `/data` (if `VOLUME_DIR` is empty)
- run `CMD`

If you'll replace `ENTRYPOINT` with your own script make sure it'll finish
with `exec setup-volume "$@"` if it doesn't use account "app" or call
`setup-volume true` before using account "app".

## Alternatives

Main rationale to create this project instead of using existing
alternatives was to automate permission/ownership management of data
volume and provide much simpler implementation to run multiple processes.

- https://github.com/just-containers/s6-overlay
- https://phusion.github.io/baseimage-docker/
