FROM crystallang/crystal:1.9.2-alpine as Builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash coreutils

RUN ./bin/build.sh

From alpine:3.17

RUN apk add --update --no-cache --force-overwrite pcre-dev pcre2-dev bash jq coreutils  
WORKDIR /opt/representer

COPY . .
COPY --from=Builder /bin/representer bin/representer

ENTRYPOINT ["/opt/representer/bin/run.sh"]
