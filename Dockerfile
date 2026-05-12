FROM crystallang/crystal:1.19.1-alpine AS Builder

# install packages required to run the representer
COPY . .

RUN apk add --no-cache bash coreutils

RUN ./bin/build.sh

FROM alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11

RUN apk add --update --no-cache --force-overwrite pcre2-dev bash jq coreutils gc-dev   
WORKDIR /opt/representer

COPY . .
COPY --from=Builder /bin/representer bin/representer

ENTRYPOINT ["/opt/representer/bin/run.sh"]
