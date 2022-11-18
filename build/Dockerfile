FROM kong:2.8.2

LABEL description="Kong 2.8.2 + kong-oidc plugin"

USER root

RUN apk update && apk upgrade

RUN apk add build-base

RUN apk add --no-cache --virtual build-deps wget tar  ca-certificates \
        && apk add --update --no-cache readline-dev outils-md5 linux-headers bsd-compat-headers m4 \
        yaml-dev build-deps bash patch bash-completion automake bash-doc make gcc g++ libgcc zlib-dev curl curl-dev autoconf \
        libtool perl pcre libxml2 libxml2-dev libmaxminddb-dev yajl yajl-dev pcre-dev unzip tzdata wrk luarocks git

RUN git clone -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity \
    && cd ModSecurity \
    && git submodule init \
    && git submodule update \
    && ./build.sh \
    && ./configure \
    && make \
    && make install \
    && mv /ModSecurity/modsecurity.conf-recommended /ModSecurity/modsecurity.conf

RUN git clone -b master --single-branch https://github.com/SpiderLabs/ModSecurity-nginx.git

RUN cd /usr/local && git clone https://github.com/coreruleset/coreruleset.git \
    && mv coreruleset/crs-setup.conf.example coreruleset/crs-setup.conf

RUN touch /usr/local/modsec_includes.conf \
    && echo "include /ModSecurity/modsecurity.conf" >> /usr/local/modsec_includes.conf \
    && echo "include /usr/local/coreruleset/crs-setup.conf" >> /usr/local/modsec_includes.conf \
    && echo "include /usr/local/coreruleset/rules/*.conf" >> /usr/local/modsec_includes.conf

RUN sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /ModSecurity/modsecurity.conf \
    && sed -i "s|SecAuditLog /var/log/modsec_audit.log|SecAuditLog /var/log/modsec/modsec_audit.log|" /ModSecurity/modsecurity.conf

RUN git clone https://github.com/Kong/kong-build-tools

RUN cd kong-build-tools/openresty-build-tools \
    && mkdir work \
    && mkdir /usr/local/kong/modsec \
    && ./kong-ngx-build -p /usr/local/kong/modsec --openresty 1.19.9.1 --openssl 1.1.1l --luarocks 3.8.0 --add-module /ModSecurity-nginx --force

RUN cp -r /usr/local/kong/modsec/openresty /usr/local/
RUN cp -r /usr/local/kong/modsec/luarocks /usr/local/
RUN cp -r /usr/local/kong/modsec/openssl /usr/local/

# Copy custom plugins if existis
# COPY ./plugins/ /usr/local/share/lua/5.1/kong/plugins/

RUN chown -R kong:kong /usr/local/share/lua/5.1/kong/

RUN luarocks install kong-oidc-1.1.0-0.src.rock && \
    luarocks install luaossl-20200709-0.src.rock OPENSSL_DIR=/usr/local/kong CRYPTO_DIR=/usr/local/kong

USER kong:kong

CMD ["kong", "docker-start"]