FROM alpine
RUN set -ex -o pipefail; \
    apk upgrade -U; \
    apk add runit; \
    rm /var/cache/apk/*;

COPY runsvdir /etc/sv/runsvdir
COPY setup-volume /sbin/

ENTRYPOINT ["/sbin/setup-volume","/data","/bin/true"]

CMD ["runsv", "/etc/sv/runsvdir"]
