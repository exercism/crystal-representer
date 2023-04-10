FROM crystallang/crystal:nightly-alpine-build

# install packages required to run the tests
RUN apk add --no-cache bash jq coreutils

WORKDIR /opt/representer
COPY . .

ENV CRYSTAL_CACHE_DIR=/tmp/.cache/.crystal

RUN ./bin/build.sh

ENTRYPOINT ["/opt/representer/bin/run.sh"]
