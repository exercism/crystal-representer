FROM crystallang/crystal:1.15.1-alpine as Builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash coreutils

RUN ./bin/build.sh

FROM alpine:3.20

RUN apk add --update --no-cache --force-overwrite pcre2-dev bash jq coreutils gc-dev   
WORKDIR /opt/representer

COPY . .
COPY --from=Builder /bin/representer bin/representer

ENTRYPOINT ["/opt/representer/bin/run.sh"]
