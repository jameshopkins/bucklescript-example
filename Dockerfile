FROM alpine:3.5

RUN apk update \
    && apk add ca-certificates bash g++ git make nodejs opam python \
    && update-ca-certificates

RUN adduser -D app
ENV APP_HOME /app

RUN mkdir $APP_HOME

RUN npm i -g yarn

# Alpine registry contains an old incompatible ninja-build.
#
# Build from source, since musl doesn't appear compatible with the compiler used
# for the ninja-build packaged binary.

RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja \
    && ./configure.py --bootstrap \
    && mv ninja /usr/local/bin

USER app

# Use the BuckleScipt version of the OCaml compiler.

RUN opam init \
    && opam update \
    && opam switch 4.02.3+buckle-master \
    && eval `opam config env`

# Install NPM deps, taking advantage of layer caching.

USER root

ADD package.json /tmp/package.json
ADD yarn.lock /tmp/yarn.lock
RUN cd /tmp && yarn \
    && cp -a /tmp/node_modules ${APP_HOME}/node_modules

# Copy application

ADD . $APP_HOME
