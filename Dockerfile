FROM alpine
RUN apk add --no-cache runit

COPY runsvdir /etc/sv/runsvdir
COPY setup-volume /usr/local/sbin/

ENTRYPOINT ["setup-volume"]

CMD ["runsv", "/etc/sv/runsvdir"]
