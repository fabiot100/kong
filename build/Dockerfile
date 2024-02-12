FROM ubuntu:jammy as build

USER root

RUN apt update && apt install gpg libreadline-dev m4 libyaml-dev bash patch bash-completion automake bash-doc make gcc g++ libgcc-11-dev zlib1g curl libcurl4-openssl-dev autoconf libtool perl libpcre3 libxml2 libxml2-dev libmaxminddb-dev libyajl-dev libpcre3-dev unzip  wrk luarocks git openssl liblmdb-dev ssdeep lua5.1 libpcre2-dev liblua5.1-0-dev -y \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install tzdata -y \
    \
    && git clone -b v3.0.10 https://github.com/SpiderLabs/ModSecurity.git \
    && cd /ModSecurity && git submodule init && git submodule update \
    && cd /ModSecurity && ./build.sh \
    && cd /ModSecurity && ./configure \
    && cd /ModSecurity && make && make install \
    && mv /ModSecurity/modsecurity.conf-recommended /ModSecurity/modsecurity.conf \
    \
    && cd / \
    && git clone -b v1.0.3 --single-branch https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && sed -i 's/ngx_log_error(NGX_LOG_INFO, (ngx_log_t \*)log, 0, "%s", msg);/ngx_log_error(NGX_LOG_WARN, (ngx_log_t \*)log, 0, "%s", msg);/' /ModSecurity-nginx/src/ngx_http_modsecurity_log.c \
    \
    && curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg \
    && mv bazel-archive-keyring.gpg /usr/share/keyrings \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
    && apt update && apt install bazel-6.1.0 python3 file libprotobuf-dev pkg-config procps valgrind apt-transport-https gnupg git make -y \
    && ln -s /usr/bin/bazel-6.1.0 /usr/bin/bazel \
    && ln -s /usr/bin/python3 /usr/bin/python \
    \
    && cd / \
    && git clone -b 3.5.0 --single-branch https://github.com/Kong/kong.git \
    && export GH_TOKEN=PUT_HERE_YOUR_GITHUB_TOKEN \
    && sed -i '/# external modules/a \ \ \ \ "--add-module=/ModSecurity-nginx",' /kong/build/openresty/BUILD.openresty.bazel \
    && cd /kong/build \
    && bazel build //build:kong --config release --verbose_failures \
    && bazel build //:kong_deb --config release --verbose_failures

FROM ubuntu:jammy

USER root

COPY --from=build /kong/bazel-kong/bazel-out/k8-opt/bin/pkg/kong.amd64.deb /

RUN apt update && apt install libreadline-dev m4 libyaml-dev bash patch bash-completion automake bash-doc make gcc g++ libgcc-11-dev zlib1g curl libcurl4-openssl-dev autoconf libtool perl libpcre3 libxml2 libxml2-dev libmaxminddb-dev libyajl-dev libpcre3-dev unzip  wrk luarocks git openssl liblmdb-dev ssdeep lua5.1 libpcre2-dev liblua5.1-0-dev -y \
    && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install tzdata -y \
    \
    && git clone -b v3.0.10 https://github.com/SpiderLabs/ModSecurity.git \
    && cd /ModSecurity && git submodule init && git submodule update \
    && cd /ModSecurity && ./build.sh \
    && cd /ModSecurity && ./configure \
    && cd /ModSecurity && make && make install \
    && mv /ModSecurity/modsecurity.conf-recommended /ModSecurity/modsecurity.conf \
    \
    && cd /usr/local \
    && git clone -b v3.3.5 --single-branch https://github.com/coreruleset/coreruleset.git \
    && mv /usr/local/coreruleset/crs-setup.conf.example /usr/local/coreruleset/crs-setup.conf \
    \
    && touch /usr/local/modsec_includes.conf \
    && echo "include /ModSecurity/modsecurity.conf" >> /usr/local/modsec_includes.conf \
    && echo "include /usr/local/coreruleset/crs-setup.conf" >> /usr/local/modsec_includes.conf \
    && echo "include /usr/local/coreruleset/rules/*.conf" >> /usr/local/modsec_includes.conf \
    \
    && sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /ModSecurity/modsecurity.conf \
    \
    && cd / \
    && apt install -y ./kong.amd64.deb \
    && rm -rf /tmp/* /ModSecurity/.git* /ModSecurity/examples /ModSecurity/src /ModSecurity/test /ModSecurity-nginx /root/.cache/* /kong.amd64.deb \
    && luarocks install lua-resty-jwt && luarocks install lua-resty-http && luarocks install lua-resty-session \
    && wget https://luarocks.org/manifests/hanszandbelt/lua-resty-openidc-1.6.0-1.src.rock \
    && luarocks install lua-resty-openidc-1.6.0-1.src.rock \
    && rm -rf lua-resty-openidc-1.6.0-1.src.rock \
    && luarocks install luaossl OPENSSL_DIR=/usr/local/kong CRYPTO_DIR=/usr/local/kong \
    && apt purge git wget unzip make automake -y \
    && apt upgrade -y \
    && apt autoremove -y

COPY docker-entrypoint.sh /docker-entrypoint.sh

# Copy custom plugins if existis
# COPY ./plugins/ /usr/local/share/lua/5.1/kong/plugins/

RUN chown -R kong:kong /usr/local/share/lua/5.1/kong \
    && chmod +x /docker-entrypoint.sh

USER kong

ENTRYPOINT ["/docker-entrypoint.sh"]

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=10s --timeout=10s --retries=10 CMD kong health

CMD ["kong", "docker-start"]