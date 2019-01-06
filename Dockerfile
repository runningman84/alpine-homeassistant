FROM alpine:latest
LABEL maintainer="Sebastien Lucas <sebastien@slucas.fr>"
LABEL Description="Home Assistant"

ARG TIMEZONE=Europe/Paris
ARG UID=1000
ARG GUID=1000
ARG MAKEFLAGS=-j4
ARG VERSION=0.84.6
ARG FRITZ_VERSION==0.6.5
ARG PLUGINS="frontend|otp|QR|sqlalchemy|netdisco|distro|xmltodict|mutagen|warrant|hue|xiaomi|fritz|hole|http|google|psutil|weather|musiccast|nmap|webpush|unifi|uptimerobot|speedtest|rxv|gTTS|wakeonlan|websocket|paho-mqtt|miio|dyson|telegram|prometheus"

ADD "https://raw.githubusercontent.com/home-assistant/home-assistant/${VERSION}/requirements_all.txt" /tmp

RUN apk add --no-cache git python3 ca-certificates nmap iputils ffmpeg mariadb-client tini python3-dev libffi-dev libressl-dev libxml2-dev libxslt-dev mariadb-connector-c-dev && \
    chmod u+s /bin/ping && \
    addgroup -g ${GUID} hass && \
    adduser -h /config -D -G hass -s /bin/sh -u ${UID} hass && \
    pip3 install --upgrade --no-cache-dir pip && \
    apk add --no-cache --virtual=build-dependencies build-base linux-headers tzdata && \
    cp "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && echo "${TIMEZONE}" > /etc/timezone && \
    sed '/^$/q' /tmp/requirements_all.txt > /tmp/requirements_core.txt && \
    sed '1,/^$/d' /tmp/requirements_all.txt > /tmp/requirements_plugins.txt && \
    egrep -e "${PLUGINS}" /tmp/requirements_plugins.txt | grep -v '#' > /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_core.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_plugins_filtered.txt && \
    pip3 install --no-cache-dir mysqlclient && \
    pip3 install --no-cache-dir homeassistant=="${VERSION}" && \
    pip3 install --no-cache-dir fritzconnection=="${FRITZ_VERSION}" && \
    apk del build-dependencies && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

EXPOSE 8123

ENTRYPOINT ["/sbin/tini"]

CMD [ "hass", "--open-ui", "--config=/config" ]
