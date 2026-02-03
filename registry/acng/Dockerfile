ARG BASE=debian
ARG PUID=0
ARG PGID=0
ARG TZ=UTC
FROM ${BASE}

ENV PUID=${PUID} PGID=${PGID} TZ=${TZ}

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      apt-cacher-ng ca-certificates cron gosu logrotate s6 rsyslog avahi-daemon &&\
  mkdir -p /var/run/apt-cacher-ng /var/log/apt-cacher-ng && \
  chown -R apt-cacher-ng:apt-cacher-ng /var/run/apt-cacher-ng /var/log/apt-cacher-ng &&\
  sed -i "s#size 5M#size 10M#g" /etc/logrotate.d/apt-cacher-ng &&\
  sed -i '/imklog/s/^/#/' /etc/rsyslog.conf &&\
  rm -rf /var/lib/apt/lists/*

COPY --chmod=755 s6 /etc/s6
COPY --chmod=755 zzz_acng.conf /etc/apt-cacher-ng/zzz_acng.conf
COPY --chmod=a+x entrypoint.sh /entrypoint.sh
RUN find /etc/s6 -type f -exec chmod 755 {} \; 2>/dev/null || true

VOLUME ["/var/cache/apt-cacher-ng"]
EXPOSE 3142

ENTRYPOINT ["/entrypoint.sh"]
CMD ["s6-svscan","/etc/s6"]
