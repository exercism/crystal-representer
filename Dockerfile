FROM crystallang/crystal:1.8.1-alpine

# install packages required to run the representer
RUN apk add --no-cache bash jq coreutils

WORKDIR /opt/representer
COPY . .

ENV CRYSTAL_CACHE_DIR=/tmp/.cache/.crystal

RUN ./bin/build.sh

ENTRYPOINT ["/opt/representer/bin/run.sh"]
