FROM nginx:1.26.3-alpine-slim@sha256:b72dec66dea425356956e863bfbccca6c1f8748f5913e094d4ca20b71e4ba2c3 AS builder

# Install temporary requirements for the dependencies
RUN apk add --no-cache bash autoconf libtool automake geoip-dev g++ gcc curl-dev libxml2-dev pcre-dev make linux-headers musl-dev gd-dev gnupg brotli-dev openssl-dev patch readline-dev yajl yajl-dev yajl-tools py3-pip python3-dev

WORKDIR /tmp/bunkerweb/deps

# Copy dependencies sources folder
COPY src/deps/misc misc
COPY src/deps/src src
COPY src/deps/deps.json deps.json
COPY --chmod=644 src/deps/install.sh install.sh

# Compile and install dependencies
RUN bash install.sh

WORKDIR /usr/share/bunkerweb

# Copy python requirements
COPY src/deps/requirements.txt /tmp/requirements-deps.txt
COPY src/common/gen/requirements.txt deps/requirements-gen.txt

# Install python requirements
RUN export MAKEFLAGS="-j$(nproc)" && \
	pip install --break-system-packages --no-cache-dir --require-hashes --ignore-installed -r /tmp/requirements-deps.txt && \
	pip install --break-system-packages --no-cache-dir --require-hashes --target deps/python -r deps/requirements-gen.txt

# Copy files
# can't exclude deps from . so we are copying everything by hand
COPY src/bw/entrypoint.sh entrypoint.sh
COPY src/bw/loading loading
COPY src/bw/lua lua
COPY src/bw/misc misc
COPY src/common/api api
COPY src/common/cli cli
COPY src/common/confs confs
COPY src/common/core core
COPY src/common/gen gen
COPY src/common/helpers helpers
COPY src/common/settings.json settings.json
COPY src/common/utils utils
COPY src/VERSION VERSION
COPY misc/*.ascii misc/

FROM nginx:1.26.3-alpine-slim@sha256:b72dec66dea425356956e863bfbccca6c1f8748f5913e094d4ca20b71e4ba2c3

# Set default umask to prevent huge recursive chmod increasing the final image size
RUN umask 027

# Install runtime dependencies
RUN apk add --no-cache openssl pcre bash python3 yajl geoip libxml2 libgd curl tzdata

# Fix CVEs
# There are no CVEs for the following packages

# Copy dependencies
COPY --from=builder --chown=0:101 /usr/share/bunkerweb /usr/share/bunkerweb

WORKDIR /usr/share/bunkerweb

# Move bwcli, create data folders and set permissions
RUN cp helpers/bwcli /usr/bin/ && \
	mkdir -p /etc/bunkerweb /var/tmp/bunkerweb /var/run/bunkerweb /var/log/bunkerweb /var/www && \
	mkdir -p /data/cache && ln -s /data/cache /var/cache/bunkerweb && \
	mkdir -p /data/lib && ln -s /data/lib /var/lib/bunkerweb && \
	mkdir -p /data/www && ln -s /data/www /var/www/html && \
	for dir in $(echo "pro configs plugins") ; do mkdir -p "/data/${dir}" && ln -s "/data/${dir}" "/etc/bunkerweb/${dir}" ; done && \
	for dir in $(echo "pro/plugins configs/http configs/stream configs/server-http configs/server-stream configs/default-server-http configs/default-server-stream configs/modsec configs/modsec-crs configs/crs-plugins-before configs/crs-plugins-after") ; do mkdir "/data/${dir}" ; done && \
	chown -R root:nginx /data /etc/nginx /var/cache/bunkerweb /var/lib/bunkerweb /var/www/html /etc/bunkerweb /var/tmp/bunkerweb /var/run/bunkerweb /var/log/bunkerweb /usr/bin/bwcli && \
	chmod -R 770 /data /etc/nginx /var/cache/bunkerweb /var/lib/bunkerweb /var/www/html /etc/bunkerweb /var/tmp/bunkerweb /var/log/bunkerweb /var/run/bunkerweb && \
	chmod 750 cli/main.py gen/main.py helpers/*.sh entrypoint.sh /usr/bin/bwcli deps/python/bin/* && \
	rm -f /var/log/bunkerweb/* && \
	ln -s /proc/1/fd/2 /var/log/bunkerweb/error.log && \
	ln -s /proc/1/fd/2 /var/log/bunkerweb/modsec_audit.log && \
	ln -s /proc/1/fd/1 /var/log/bunkerweb/access.log

LABEL maintainer="Bunkerity <contact@bunkerity.com>"
LABEL version="1.6.1"
LABEL url="https://www.bunkerweb.io"
LABEL bunkerweb.type="bunkerweb"
LABEL bunkerweb.INSTANCE="bunkerweb"

EXPOSE 8080/tcp 8443/tcp 8443/udp

USER nginx:nginx

HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=6 CMD /usr/share/bunkerweb/helpers/healthcheck.sh

ENTRYPOINT [ "./entrypoint.sh" ]
