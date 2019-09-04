FROM alpine:3.10
LABEL maintainer="Philipp Hellmich <phil@hellmi.de>"
LABEL Description="Home Assistant"

ARG TIMEZONE=Europe/Paris
ARG UID=1000
ARG GUID=1000
ARG MAKEFLAGS=-j16
ARG VERSION=0.98.1
ARG FRITZ_VERSION==0.6.5
ARG PLUGINS="frontend|otp|QR|sqlalchemy|netdisco|distro|xmltodict|mutagen|warrant|hue|xiaomi|fritz|hole|http|google|psutil|weather|musiccast|nmap|webpush|unifi|uptimerobot|speedtest|rxv|gTTS|wakeonlan|websocket|paho-mqtt|miio|purecoollink|telegram|prometheus|pyhomematic|panasonic_viera|nabucasa|PyNaCl|purecool|influxdb|pillow"

ADD "https://raw.githubusercontent.com/home-assistant/home-assistant/${VERSION}/requirements_all.txt" /tmp

RUN apk add --no-cache git python3 ca-certificates nmap iputils ffmpeg mariadb-client tini libxml2 libxslt && \
    chmod u+s /bin/ping && \
    addgroup -g ${GUID} hass && \
    adduser -D -G hass -s /bin/sh -u ${UID} hass && \
    pip3 install --upgrade --no-cache-dir pip && \
    apk add --no-cache --virtual=build-dependencies build-base linux-headers tzdata python3-dev libffi-dev libressl-dev libxml2-dev libxslt-dev mariadb-connector-c-dev && \
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && echo "${TIMEZONE}" > /etc/timezone && \
    sed '/^$/q' /tmp/requirements_all.txt > /tmp/requirements_core.txt && \
    sed '1,/^$/d' /tmp/requirements_all.txt > /tmp/requirements_plugins.txt && \
    egrep -i -e "${PLUGINS}" /tmp/requirements_plugins.txt | grep -v '#' > /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_core.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir mysqlclient && \
    pip3 install --no-cache-dir homeassistant=="${VERSION}" && \
    pip3 install --no-cache-dir fritzconnection=="${FRITZ_VERSION}" && \
    pip3 uninstall -y pycrypto && \
    pip3 uninstall -y pycryptodome && \
    pip3 install --no-cache-dir pycryptodome && \
    apk del build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

EXPOSE 8123

VOLUME /config

ENTRYPOINT ["/sbin/tini", "--"]

CMD [ "hass", "--open-ui", "--config=/config" ]
