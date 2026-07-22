FROM crystallang/crystal:1.20.3-alpine AS Builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash coreutils

RUN ./bin/build.sh

FROM alpine:3.23.5@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40

RUN apk add --update --no-cache --force-overwrite pcre2-dev bash jq coreutils gc-dev   
WORKDIR /opt/representer

COPY . .
COPY --from=Builder /bin/representer bin/representer

ENTRYPOINT ["/opt/representer/bin/run.sh"]
