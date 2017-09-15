FROM alpine

COPY sv /etc/sv/
COPY setup-volume /usr/local/sbin/

RUN set -ex -o pipefail; \
    apk add --no-cache runit socklog dcron; \
    ln -s /etc/sv/socklog-unix /etc/service/syslog

ENTRYPOINT ["setup-volume"]

CMD ["runsv", "/etc/sv/runsvdir"]
