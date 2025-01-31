FROM alpine:latest

RUN apk add --no-cache \
    wget \
    curl \
    openssl \
    util-linux \
    bash

WORKDIR /app

COPY ./bin /app/bin
RUN chmod +x /app/bin/*

ENTRYPOINT ["bin/ubuntu-installer.sh"]

