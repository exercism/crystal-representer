FROM crystallang/crystal:1.22.1-alpine AS builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash coreutils

RUN ./bin/build.sh

FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

RUN apk add --update --no-cache --force-overwrite pcre2-dev bash jq coreutils gc-dev   
WORKDIR /opt/representer

COPY . .
COPY --from=builder /bin/representer bin/representer

ENTRYPOINT ["/opt/representer/bin/run.sh"]
