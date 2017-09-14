FROM alpine
RUN apk add --no-cache runit

COPY runsvdir /etc/sv/runsvdir
COPY setup-volume /sbin/

ENTRYPOINT ["/sbin/setup-volume","/data"]

CMD ["runsv", "/etc/sv/runsvdir"]
