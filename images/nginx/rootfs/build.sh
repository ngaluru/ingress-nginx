#!/bin/bash

# Copyright 2023 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

export NGINX_VERSION=1.27.1

# Check for recent changes: https://github.com/vision5/ngx_devel_kit/compare/v0.3.3...master
export NDK_VERSION=v0.3.3

# Check for recent changes: https://github.com/openresty/set-misc-nginx-module/compare/v0.33...master
export SETMISC_VERSION=v0.33

# Check for recent changes: https://github.com/openresty/headers-more-nginx-module/compare/v0.37...master
export MORE_HEADERS_VERSION=v0.37

# Check for recent changes: https://github.com/atomx/nginx-http-auth-digest/compare/v1.0.0...master
export NGINX_DIGEST_AUTH=v1.0.0

# Check for recent changes: https://github.com/SpiderLabs/ModSecurity-nginx/compare/v1.0.3...master
export MODSECURITY_VERSION=v1.0.3

# Check for recent changes: https://github.com/SpiderLabs/ModSecurity/compare/v3.0.13...v3/master
export MODSECURITY_LIB_VERSION=v3.0.13

# Check for recent changes: https://github.com/coreruleset/coreruleset/compare/v4.10.0...main
export OWASP_MODSECURITY_CRS_VERSION=v4.10.0

# Check for recent changes: https://github.com/openresty/lua-nginx-module/compare/v0.10.27...master
export LUA_NGX_VERSION=v0.10.27

# Check for recent changes: https://github.com/openresty/stream-lua-nginx-module/compare/v0.0.15...master
export LUA_STREAM_NGX_VERSION=v0.0.15

# Check for recent changes: https://github.com/openresty/lua-upstream-nginx-module/compare/v0.07...master
export LUA_UPSTREAM_VERSION=v0.07

# Check for recent changes: https://github.com/openresty/lua-cjson/compare/2.1.0.14...master
export LUA_CJSON_VERSION=2.1.0.14

# Check for recent changes: https://github.com/leev/ngx_http_geoip2_module/compare/445df24ef3781e488cee3dfe8a1e111997fc1dfe...master
export GEOIP2_VERSION=445df24ef3781e488cee3dfe8a1e111997fc1dfe

# Check for recent changes: https://github.com/openresty/luajit2/compare/v2.1-20240815...v2.1-agentzh
export LUAJIT_VERSION=v2.1-20240815

# Check for recent changes: https://github.com/openresty/lua-resty-balancer/compare/v0.05...master
export LUA_RESTY_BALANCER=v0.05

# Check for recent changes: https://github.com/openresty/lua-resty-lrucache/compare/v0.15...master
export LUA_RESTY_CACHE=v0.15

# Check for recent changes: https://github.com/openresty/lua-resty-core/compare/v0.1.30...master
export LUA_RESTY_CORE=v0.1.30

# Check for recent changes: https://github.com/cloudflare/lua-resty-cookie/compare/f418d77082eaef48331302e84330488fdc810ef4...master
export LUA_RESTY_COOKIE_VERSION=f418d77082eaef48331302e84330488fdc810ef4

# Check for recent changes: https://github.com/openresty/lua-resty-dns/compare/v0.23...master
export LUA_RESTY_DNS=v0.23

# Check for recent changes: https://github.com/ledgetech/lua-resty-http/compare/v0.17.2...master
export LUA_RESTY_HTTP=v0.17.2

# Check for recent changes: https://github.com/openresty/lua-resty-lock/compare/v0.09...master
export LUA_RESTY_LOCK=v0.09

# Check for recent changes: https://github.com/openresty/lua-resty-upload/compare/v0.11...master
export LUA_RESTY_UPLOAD_VERSION=v0.11

# Check for recent changes: https://github.com/openresty/lua-resty-string/compare/v0.16...master
export LUA_RESTY_STRING_VERSION=v0.16

# Check for recent changes: https://github.com/openresty/lua-resty-memcached/compare/v0.17...master
export LUA_RESTY_MEMCACHED_VERSION=v0.17

# Check for recent changes: https://github.com/openresty/lua-resty-redis/compare/v0.31...master
export LUA_RESTY_REDIS_VERSION=v0.31

# Check for recent changes: https://github.com/api7/lua-resty-ipmatcher/compare/3e93c53eb8c9884efe939ef070486a0e507cc5be...master
export LUA_RESTY_IPMATCHER_VERSION=3e93c53eb8c9884efe939ef070486a0e507cc5be

# Check for recent changes: https://github.com/microsoft/mimalloc/compare/v2.1.9...master
export MIMALOC_VERSION=v2.1.9

# Check for recent changes: https://github.com/open-telemetry/opentelemetry-cpp/compare/v1.18.0...main
export OPENTELEMETRY_CPP_VERSION=v1.18.0

# Check for recent changes: https://github.com/open-telemetry/opentelemetry-proto/compare/v1.5.0...main
export OPENTELEMETRY_PROTO_VERSION=v1.5.0
export NGINX_OTEL_VERSION="0.1.1"

export BUILD_PATH=/tmp/build

export GITHUB=https://github.com

ARCH=$(uname -m)

get_src()
{
  hash="$1"
  url="$2"
  dest="${3-}"
  ARGS=""
  f=$(basename "$url")

  echo "Downloading $url"

  curl -sSL "$url" -o "$f"
  # No check hash if it equal to "abc123"
  if [ "$hash" != "abc123" ]; then
    echo "$hash  $f" | sha256sum -c - || exit 10
  fi
  if [ ! -z "$dest" ]; then
        mkdir ${BUILD_PATH}/${dest}
        ARGS="-C ${BUILD_PATH}/${dest} --strip-components=1"
  fi
  tar xvzf "$f" $ARGS
  rm -rf "$f"
}

# install required packages to build
# Dependencies from "ninja" and below are OTEL dependencies
apk add \
  bash \
  gcc \
  clang \
  libc-dev \
  make \
  automake \
  openssl-dev \
  pcre-dev \
  zlib-dev \
  linux-headers \
  libxslt-dev \
  gd-dev \
  perl-dev \
  libedit-dev \
  mercurial \
  alpine-sdk \
  findutils \
  curl \
  ca-certificates \
  patch \
  libaio-dev \
  openssl \
  cmake \
  util-linux \
  lmdb-tools \
  wget \
  curl-dev \
  libprotobuf \
  git g++ pkgconf flex bison doxygen yajl-dev lmdb-dev libtool autoconf libxml2 libxml2-dev \
  python3 \
  libmaxminddb-dev \
  bc \
  unzip \
  dos2unix \
  yaml-cpp \
  coreutils \
  ninja \
  gtest-dev \
  git \
  build-base \
  pkgconfig \
  c-ares-dev \
  re2-dev \
  grpc-dev \
  protobuf-dev

# apk add -X http://dl-cdn.alpinelinux.org/alpine/edge/testing opentelemetry-cpp-dev

# There is some bug with some platforms and git, so force HTTP/1.1
git config --global http.version HTTP/1.1
git config --global http.postBuffer 157286400

mkdir -p /etc/nginx

mkdir --verbose -p "$BUILD_PATH"
cd "$BUILD_PATH"

# download, verify and extract the source files
get_src bd7ba68a6ce1ea3768b771c7e2ab4955a59fb1b1ae8d554fedb6c2304104bdfc \
        "https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz"

get_src faa2fcd5168b10764d35081356511d5f84db5c526a1aa4b6add2db94b6853b2b \
        "${GITHUB}/vision5/ngx_devel_kit/archive/$NDK_VERSION.tar.gz" "ngx_devel_kit"

get_src b149109d5983cf8290d614654a878899a68b0c8902b64c934d06f47cd50ffe2e \
        "${GITHUB}/open-telemetry/opentelemetry-cpp/archive/$OPENTELEMETRY_CPP_VERSION.tar.gz" "opentelemetry-cpp"

get_src 08f40636adbc5f33d2084bd8e7b64e491dd0239d1a95021dbffbdf1ca8cea454 \
        "${GITHUB}/open-telemetry/opentelemetry-proto/archive/$OPENTELEMETRY_PROTO_VERSION.tar.gz" "opentelemetry-proto"

get_src cd5e2cc834bcfa30149e7511f2b5a2183baf0b70dc091af717a89a64e44a2985 \
        "${GITHUB}/openresty/set-misc-nginx-module/archive/$SETMISC_VERSION.tar.gz" "set-misc-nginx-module"

get_src cf6e169d6b350c06d0c730b0eaf4973394026ad40094cddd3b3a5b346577019d \
        "${GITHUB}/openresty/headers-more-nginx-module/archive/$MORE_HEADERS_VERSION.tar.gz" "headers-more-nginx-module"

get_src f09851e6309560a8ff3e901548405066c83f1f6ff88aa7171e0763bd9514762b \
        "${GITHUB}/atomx/nginx-http-auth-digest/archive/$NGINX_DIGEST_AUTH.tar.gz" "nginx-http-auth-digest"

get_src 32a42256616cc674dca24c8654397390adff15b888b77eb74e0687f023c8751b \
        "${GITHUB}/SpiderLabs/ModSecurity-nginx/archive/$MODSECURITY_VERSION.tar.gz" "ModSecurity-nginx"

get_src a0a5e616c4a0a32e48899d12242fed5a371f69a85f11ff274a87a2f02f419876 \
        "${GITHUB}/openresty/lua-nginx-module/archive/$LUA_NGX_VERSION.tar.gz" "lua-nginx-module"

get_src ecf5c2afd345149cef19bf2e3e196bf1c514ca85e778f853f80a379284b70de1 \
        "${GITHUB}/openresty/stream-lua-nginx-module/archive/$LUA_STREAM_NGX_VERSION.tar.gz" "stream-lua-nginx-module"

get_src 2a69815e4ae01aa8b170941a8e1a10b6f6a9aab699dee485d58f021dd933829a \
        "${GITHUB}/openresty/lua-upstream-nginx-module/archive/$LUA_UPSTREAM_VERSION.tar.gz" "lua-upstream-nginx-module"

get_src 9e59ec13c301c8b2855838b1248def49ef348a3e7563fabef677431706718145 \
        "${GITHUB}/openresty/luajit2/archive/$LUAJIT_VERSION.tar.gz" "luajit2"

get_src 5e2113ed09cdd710908df8c6d1630616eeacb9216ef8705a06c25733394ddf28 \
        "${GITHUB}/leev/ngx_http_geoip2_module/archive/$GEOIP2_VERSION.tar.gz" "ngx_http_geoip2_module"

get_src deb4ab1ffb9f3d962c4b4a2c4bdff692b86a209e3835ae71ebdf3b97189e40a9 \
        "${GITHUB}/openresty/lua-resty-upload/archive/$LUA_RESTY_UPLOAD_VERSION.tar.gz" "lua-resty-upload"

get_src 77f006a97fd4a3be4a82dcf2d5f1482e399b70fb35454c5b5ad4b97ff1dded0d \
        "${GITHUB}/openresty/lua-resty-string/archive/$LUA_RESTY_STRING_VERSION.tar.gz" "lua-resty-string"

get_src 8b2ff4edefc240dea0d3adb9dd065a42e8c09e06ba8bb0a188464cf76c9e4d06 \
        "${GITHUB}/openresty/lua-resty-balancer/archive/$LUA_RESTY_BALANCER.tar.gz" "lua-resty-balancer"

get_src adc7781ddaeab9341b82033a6c06b0d190d4c6d1c2dddd46f6965ce9e57a0310 \
        "${GITHUB}/openresty/lua-resty-core/archive/$LUA_RESTY_CORE.tar.gz" "lua-resty-core"

get_src 14cac5c7a4520b33449a1fc961344556b8b6a2a2c6b739b0e46e3002e6e605bc \
        "${GITHUB}/openresty/lua-cjson/archive/$LUA_CJSON_VERSION.tar.gz" "lua-cjson"

get_src c0217456f4c36bb9ebbf7dbcd733e3d70734330364c88df73e703c4777521ff9 \
        "${GITHUB}/cloudflare/lua-resty-cookie/archive/$LUA_RESTY_COOKIE_VERSION.tar.gz" "lua-resty-cookie"

get_src 8cf1a22e0d5b8f35cb0b2e14c58fcb3aa505a8fb6e956817f0cdb1f06593f072 \
        "${GITHUB}/openresty/lua-resty-lrucache/archive/$LUA_RESTY_CACHE.tar.gz" "lua-resty-lrucache"

get_src b4ddcd47db347e9adf5c1e1491a6279a6ae2a3aff3155ef77ea0a65c998a69c1 \
        "${GITHUB}/openresty/lua-resty-lock/archive/$LUA_RESTY_LOCK.tar.gz" "lua-resty-lock"

get_src ecc80b91bfb4f795b8a80acfa69e1778288ef60649ddd87f30a9c4a57ac5da79 \
        "${GITHUB}/openresty/lua-resty-dns/archive/$LUA_RESTY_DNS.tar.gz" "lua-resty-dns"

get_src 3da18ca8582243eff28302591e36651dc7fab046e77336aa4a6fa718bccce4a2 \
        "${GITHUB}/ledgetech/lua-resty-http/archive/$LUA_RESTY_HTTP.tar.gz" "lua-resty-http"

get_src 02733575c4aed15f6cab662378e4b071c0a4a4d07940c4ef19a7319e9be943d4 \
        "${GITHUB}/openresty/lua-resty-memcached/archive/$LUA_RESTY_MEMCACHED_VERSION.tar.gz" "lua-resty-memcached"

get_src 927389dda41f07038481f89f925c44328446b2ee6ce3e667eeef51b7bd0ee836 \
        "${GITHUB}/openresty/lua-resty-redis/archive/$LUA_RESTY_REDIS_VERSION.tar.gz" "lua-resty-redis"

get_src bf4f89c0c00d1e986260d22180cbccbd2016eb054b5c2adcc1b6ee0ff773032f \
        "${GITHUB}/api7/lua-resty-ipmatcher/archive/$LUA_RESTY_IPMATCHER_VERSION.tar.gz" "lua-resty-ipmatcher"

get_src dd8ff701691f19bf4e225d42ef0d3d5e6ca0e03498ee4f044a0402e4697e4a20 \
        "${GITHUB}/microsoft/mimalloc/archive/${MIMALOC_VERSION}.tar.gz" "mimalloc"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))

export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}

# Install luajit from openresty fork
export LUAJIT_LIB=/usr/local/lib
export LUA_LIB_DIR="$LUAJIT_LIB/lua"
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd "$BUILD_PATH/luajit2"
make CCDEBUG=-g
make install

ln -s /usr/local/bin/luajit /usr/local/bin/lua
ln -s "$LUAJIT_INC" /usr/local/include/lua

cd "$BUILD_PATH/opentelemetry-cpp"
export CXXFLAGS="-DBENCHMARK_HAS_NO_INLINE_ASSEMBLY"
cmake -B build -G Ninja -Wno-dev \
        -DOTELCPP_PROTO_PATH="${BUILD_PATH}/opentelemetry-proto/" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING="OFF" \
        -DBUILD_W3CTRACECONTEXT_TEST="OFF" \
        -DCMAKE_BUILD_TYPE=None \
        -DWITH_ABSEIL=ON \
        -DWITH_STL=ON \
        -DWITH_EXAMPLES=OFF \
        -DWITH_ZPAGES=OFF \
        -DWITH_OTLP_GRPC=ON \
        -DWITH_OTLP_HTTP=ON \
        -DWITH_ZIPKIN=ON \
        -DWITH_PROMETHEUS=OFF \
        -DWITH_ASYNC_EXPORT_PREVIEW=OFF \
        -DWITH_METRICS_EXEMPLAR_PREVIEW=OFF
      cmake --build build
      cmake --install build

# Git tuning
git config --global --add core.compression -1

# Get Brotli source and deps
cd "$BUILD_PATH"
git clone --depth=100 ${GITHUB}/google/ngx_brotli.git
cd ngx_brotli
git reset --hard a71f9312c2deb28875acc7bacfdd5695a111aa53
git submodule init
git submodule update

cd "$BUILD_PATH"
git clone --depth=1 ${GITHUB}/ssdeep-project/ssdeep
cd ssdeep/

./bootstrap
./configure

make
make install

# build modsecurity library
cd "$BUILD_PATH"
git clone -n ${GITHUB}/SpiderLabs/ModSecurity
cd ModSecurity/
git checkout $MODSECURITY_LIB_VERSION
git submodule init
git submodule update

sh build.sh

# https://github.com/SpiderLabs/ModSecurity/issues/1909#issuecomment-465926762
sed -i '115i LUA_CFLAGS="${LUA_CFLAGS} -DWITH_LUA_JIT_2_1"' build/lua.m4
sed -i '117i AC_SUBST(LUA_CFLAGS)' build/lua.m4

./configure \
  --disable-doxygen-doc \
  --disable-doxygen-html \
  --disable-examples

make
make install

mkdir -p /etc/nginx/modsecurity
cp modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
cp unicode.mapping /etc/nginx/modsecurity/unicode.mapping

# Replace serial logging with concurrent
sed -i 's|SecAuditLogType Serial|SecAuditLogType Concurrent|g' /etc/nginx/modsecurity/modsecurity.conf

# Concurrent logging implies the log is stored in several files
echo "SecAuditLogStorageDir /var/log/audit/" >> /etc/nginx/modsecurity/modsecurity.conf

# Download owasp modsecurity crs
cd /etc/nginx/

git clone -b $OWASP_MODSECURITY_CRS_VERSION ${GITHUB}/coreruleset/coreruleset
mv coreruleset owasp-modsecurity-crs
cd owasp-modsecurity-crs

mv crs-setup.conf.example crs-setup.conf
mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
cd ..

# OWASP CRS v4 rules
echo "
Include /etc/nginx/owasp-modsecurity-crs/crs-setup.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-922-MULTIPART-ATTACK.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-934-APPLICATION-ATTACK-GENERIC.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-944-APPLICATION-ATTACK-JAVA.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-955-WEB-SHELLS.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf
Include /etc/nginx/owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
" > /etc/nginx/owasp-modsecurity-crs/nginx-modsecurity.conf

# NGINX compiles a small test program to check if an added module works as expected.
#
# ModSecurity-nginx provides 'printf("hello");' as a test, but newer versions of GCC,
# as included in Alpine 3.21, do not allow implicit declaration of function 'printf':
#
#   objs/autotest.c:7:5: error: implicit declaration of function 'printf' [-Wimplicit-function-declaration]
#
# For this reason we replace 'printf("hello");' by 'msc_init();', which is always available.
#
# This fix is taken from a PR, that has been proposed to the ModSecurity-nginx project:
#
#   https://github.com/owasp-modsecurity/ModSecurity-nginx/pull/275
#
sed -i "s/ngx_feature_test='printf(\"hello\");'/ngx_feature_test='msc_init();'/" $BUILD_PATH/ModSecurity-nginx/config

# build nginx
cd "$BUILD_PATH/nginx-$NGINX_VERSION"

# apply nginx patches
for PATCH in `ls /patches`;do
  echo "Patch: $PATCH"
  if [[ "$PATCH" == *.txt ]]; then
    patch -p0 < /patches/$PATCH
  else
    patch -p1 < /patches/$PATCH
  fi
done

WITH_FLAGS="--with-debug \
  --with-compat \
  --with-pcre-jit \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_auth_request_module \
  --with-http_addition_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_ssl_preread_module \
  --with-threads \
  --with-http_secure_link_module \
  --with-http_gunzip_module"

# "Combining -flto with -g is currently experimental and expected to produce unexpected results."
# https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
CC_OPT="-g -O2 -fPIE -fstack-protector-strong \
  -Wformat \
  -Werror=format-security \
  -Wno-deprecated-declarations \
  -fno-strict-aliasing \
  -D_FORTIFY_SOURCE=2 \
  --param=ssp-buffer-size=4 \
  -DTCP_FASTOPEN=23 \
  -fPIC \
  -Wno-cast-function-type"

LD_OPT="-fPIE -fPIC -pie -Wl,-z,relro -Wl,-z,now"

if [[ ${ARCH} != "aarch64" ]]; then
  WITH_FLAGS+=" --with-file-aio"
fi

if [[ ${ARCH} == "x86_64" ]]; then
  CC_OPT+=' -m64 -mtune=generic'
fi

WITH_MODULES=" \
  --add-module=$BUILD_PATH/ngx_devel_kit \
  --add-module=$BUILD_PATH/set-misc-nginx-module \
  --add-module=$BUILD_PATH/headers-more-nginx-module \
  --add-module=$BUILD_PATH/lua-nginx-module \
  --add-module=$BUILD_PATH/stream-lua-nginx-module \
  --add-module=$BUILD_PATH/lua-upstream-nginx-module \
  --add-dynamic-module=$BUILD_PATH/nginx-http-auth-digest \
  --add-dynamic-module=$BUILD_PATH/ModSecurity-nginx \
  --add-dynamic-module=$BUILD_PATH/ngx_http_geoip2_module \
  --add-dynamic-module=$BUILD_PATH/ngx_brotli"

./configure \
  --prefix=/usr/local/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --modules-path=/etc/nginx/modules \
  --http-log-path=/var/log/nginx/access.log \
  --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  ${WITH_FLAGS} \
  --without-mail_pop3_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-http_uwsgi_module \
  --without-http_scgi_module \
  --with-cc-opt="${CC_OPT}" \
  --with-ld-opt="${LD_OPT}" \
  --user=www-data \
  --group=www-data \
  ${WITH_MODULES}

make
make modules
make install

# Check for recent changes: https://github.com/open-telemetry/opentelemetry-cpp-contrib/compare/8933841f0a7f8737f61404cf0a64acf6b079c8a5...main
export OPENTELEMETRY_CONTRIB_COMMIT=8933841f0a7f8737f61404cf0a64acf6b079c8a5
cd "$BUILD_PATH"

git clone ${GITHUB}/open-telemetry/opentelemetry-cpp-contrib.git opentelemetry-cpp-contrib-${OPENTELEMETRY_CONTRIB_COMMIT}

cd ${BUILD_PATH}/opentelemetry-cpp-contrib-${OPENTELEMETRY_CONTRIB_COMMIT}
git reset --hard ${OPENTELEMETRY_CONTRIB_COMMIT}

export OTEL_TEMP_INSTALL=/tmp/otel
mkdir -p ${OTEL_TEMP_INSTALL}

cd ${BUILD_PATH}/opentelemetry-cpp-contrib-${OPENTELEMETRY_CONTRIB_COMMIT}/instrumentation/nginx
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release \
        -G Ninja \
        -DCMAKE_CXX_STANDARD=17 \
        -DCMAKE_INSTALL_PREFIX=${OTEL_TEMP_INSTALL} \
        -DBUILD_SHARED_LIBS=ON \
        -DNGINX_VERSION=${NGINX_VERSION} \
        ..
cmake --build . -j ${CORES} --target install

mkdir -p /etc/nginx/modules
cp ${OTEL_TEMP_INSTALL}/otel_ngx_module.so /etc/nginx/modules/otel_ngx_module.so


cd "$BUILD_PATH/lua-resty-core"
make install

cd "$BUILD_PATH/lua-resty-balancer"
make all
make install

export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1
ln -s $LUA_INCLUDE_DIR /usr/include/lua5.1

cd "$BUILD_PATH/lua-cjson"
make all
make install

cd "$BUILD_PATH/lua-resty-cookie"
make all
make install

cd "$BUILD_PATH/lua-resty-lrucache"
make install

cd "$BUILD_PATH/lua-resty-dns"
make install

cd "$BUILD_PATH/lua-resty-lock"
make install

# required for OCSP verification
cd "$BUILD_PATH/lua-resty-http"
make install

cd "$BUILD_PATH/lua-resty-upload"
make install

cd "$BUILD_PATH/lua-resty-string"
make install

cd "$BUILD_PATH/lua-resty-memcached"
make install

cd "$BUILD_PATH/lua-resty-redis"
make install

cd "$BUILD_PATH/lua-resty-ipmatcher"
INST_LUADIR=/usr/local/lib/lua make install

cd "$BUILD_PATH/mimalloc"
mkdir -p out/release
cd out/release

cmake ../..

make
make install

# update image permissions
writeDirs=( \
  /etc/nginx \
  /usr/local/nginx \
  /opt/modsecurity/var/log \
  /opt/modsecurity/var/upload \
  /opt/modsecurity/var/audit \
  /var/log/audit \
  /var/log/nginx \
);

adduser -S -D -H -u 101 -h /usr/local/nginx -s /sbin/nologin -G www-data -g www-data www-data

for dir in "${writeDirs[@]}"; do
  mkdir -p ${dir};
  chown -R www-data:www-data ${dir};
done

rm -rf /etc/nginx/owasp-modsecurity-crs/.git
rm -rf /etc/nginx/owasp-modsecurity-crs/tests

# remove .a files
find /usr/local -name "*.a" -print | xargs /bin/rm
