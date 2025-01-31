FROM alpine:latest

RUN apk add --no-cache \
    wget \
    curl \
    openssl \
    util-linux \
    bash

COPY ubuntu-installer.sh /usr/local/bin/ubuntu-installer
RUN chmod +x /usr/local/bin/ubuntu-installer

ENTRYPOINT ["ubuntu-installer"]

