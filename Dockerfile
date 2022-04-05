FROM alpine:3.15.4
SHELL ["/bin/ash","-e","-o","pipefail","-x","-c"]

COPY sv /etc/sv/
COPY setup-volume /usr/local/sbin/

RUN apk add --no-cache runit=~2.1.2 socklog=~2.1.0 dcron=~4.5; \
    ln -s /etc/sv/socklog-unix /etc/service/syslog

WORKDIR /home/app

ENTRYPOINT ["setup-volume"]

CMD ["runsv", "/etc/sv/runsvdir"]
