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
  - Account "app" will be the owner of attached data volume directory.
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
ENV VOLUME_DIR=/app/volume/dir
```

These environment variables can be provided when starting container:

- `APP_UID`, `APP_GID`: numeric UID/GID to be used for "app" account and
  to set ownership for root directory of attached volume.
  - If `APP_UID=0` then it will be ignored.
  - Use values between 1000 and 60000 to avoid conflicts with existing
    accounts.
- `VOLUME_DIR`: directory with data volume (`/data` by default)

## How it works

When container starts `/sbin/setup-volume` will be executed as
`ENTRYPOINT` to:

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

## Alternatives

Main rationale to create this project instead of using existing
alternatives was to automate permission/ownership management of data
volume and provide much simpler implementation to run multiple processes.

- https://github.com/just-containers/s6-overlay
- https://phusion.github.io/baseimage-docker/
