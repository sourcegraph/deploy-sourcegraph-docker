FROM alpine:latest as gen

ENV GEN_VERSION 0.7.4
ADD https://github.com/jwilder/docker-gen/releases/download/$GEN_VERSION/docker-gen-alpine-linux-amd64-$GEN_VERSION.tar.gz /tmp/
RUN tar xvf /tmp/docker-gen-alpine-linux-amd64-$GEN_VERSION.tar.gz -C /usr/local/bin

FROM alpine:latest as forego

ENV FOREGO_VERSION v0.16.1
ADD https://github.com/jwilder/forego/releases/download/$FOREGO_VERSION/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

FROM index.docker.io/caddy/caddy:2.1.1-alpine

RUN apk add --no-cache bash

ENV DOCKER_HOST unix:///tmp/docker.sock

# Tools
COPY --from=gen /usr/local/bin/docker-gen /usr/local/bin/docker-gen
COPY --from=forego /usr/local/bin/forego /usr/local/bin/forego

# Config
COPY Caddyfile.tmpl /etc/docker-gen/template/
COPY docker-gen.cfg /etc/docker-gen/config/

# Entry
WORKDIR /
COPY Procfile /
COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
CMD ["/usr/local/bin/forego", "start", "-r"]
