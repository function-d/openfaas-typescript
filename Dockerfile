ARG TARGETPLATFORM
ARG BUILDPLATFORM

FROM --platform=${TARGETPLATFORM:-linux/amd64} node:12-alpine as build

WORKDIR /root/

# Turn down the verbosity to default level.
ENV NPM_CONFIG_LOGLEVEL warn

RUN mkdir -p /home/app

# Wrapper/boot-strapper
WORKDIR /home/app
COPY package.json ./

# This ordering means the npm installation is cached for the outer function handler.
RUN npm i
# Install typescript for later compilation
RUN npm i -g typescript

# Copy outer function handler
COPY index.js ./

# COPY function node packages and install, adding this as a separate
# entry allows caching of npm install
WORKDIR /home/app/function

# COPY function files and folders
COPY function/ ./


# Set correct permissions to use non root user
WORKDIR /home/app/

# Copy tsconfig file
COPY tsconfig.build.json ./
# Compile the ts file to js.
RUN tsc -p tsconfig.build.json

FROM --platform=${TARGETPLATFORM:-linux/amd64} openfaas/of-watchdog:0.7.2 as watchdog
FROM --platform=${TARGETPLATFORM:-linux/amd64} node:12-alpine as ship

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

RUN apk --no-cache add curl ca-certificates \
    && addgroup -S app && adduser -S -g app app

WORKDIR /root/

# Turn down the verbosity to default level.
ENV NPM_CONFIG_LOGLEVEL warn

# Wrapper/boot-strapper
WORKDIR /home/app
COPY package.json ./

# This ordering means the npm installation is cached for the outer function handler.
RUN npm i --only=prod

# Copy outer function handler
COPY index.js ./
COPY --from=build /home/app/function/dist ./function/dist

# COPY function node packages and install, adding this as a separate
# entry allows caching of npm install

WORKDIR /home/app/function

COPY function/*.json ./

RUN npm i --only=prod || :

# Set correct permissions to use non root user
WORKDIR /home/app/

# chmod for tmp is for a buildkit issue (@alexellis)
RUN chown app:app -R /home/app \
    && chmod 777 /tmp

USER app

ENV cgi_headers="true"
ENV fprocess="node index.js"
ENV mode="http"
ENV upstream_url="http://127.0.0.1:3000"

ENV exec_timeout="10s"
ENV write_timeout="15s"
ENV read_timeout="15s"

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]