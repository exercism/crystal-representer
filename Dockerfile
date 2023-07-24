FROM crystallang/crystal:1.9-alpine as Builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash jq coreutils

RUN ./bin/build.sh

From alpine:3.17
RUN apk add --update --no-cache --force-overwrite    pcre-dev pcre2-dev     
#libxml2-dev libxml2-static openssl-dev openssl-libs-static tzdata yaml-static zlib-static xz-static
WORKDIR /opt/representer
COPY . .
COPY --from=Builder /bin/representer bin/representer

RUN apk add --no-cache bash jq coreutils

ENTRYPOINT ["/opt/representer/bin/run.sh"]
