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
# Check for recent changes: https://github.com/openresty/lua-nginx-module/compare/v0.10.27...master
export LUA_NGX_VERSION=v0.10.27
# Check for recent changes: https://github.com/openresty/stream-lua-nginx-module/compare/v0.0.15...master
export LUA_STREAM_NGX_VERSION=v0.0.15
# Check for recent changes: https://github.com/openresty/lua-upstream-nginx-module/compare/v0.07...master
export LUA_UPSTREAM_VERSION=v0.07
# Check for recent changes: https://github.com/openresty/luajit2/compare/v2.1-20240815...v2.1-agentzh
export LUAJIT_VERSION=v2.1-20241113
# Check for recent changes: https://github.com/openresty/lua-resty-lrucache/compare/v0.15...master
export LUA_RESTY_CACHE=v0.15
# Check for recent changes: https://github.com/openresty/lua-resty-core/compare/v0.1.30...master
export LUA_RESTY_CORE=v0.1.30
# Check for recent changes: https://github.com/microsoft/mimalloc/compare/v2.1.9...master
export MIMALOC_VERSION=v2.1.9
# Check for recent changes: https://github.com/open-telemetry/opentelemetry-cpp/compare/v1.18.0...main
export OPENTELEMETRY_CPP_VERSION=v1.18.0
# Check for recent changes: https://github.com/open-telemetry/opentelemetry-proto/compare/v1.5.0...main
#export OPENTELEMETRY_PROTO_VERSION=v1.5.0
export OPENTELEMETRY_PROTO_VERSION=v1.4.0
export NGINX_OTEL_VERSION="a45a594"
#export NGINX_OTEL_VERSION="0.1.1"
# Check for recent changes: https://github.com/open-telemetry/opentelemetry-cpp-contrib/compare/nginx/v0.1.1...main
export OPENTELEMETRY_CONTRIB_VERSION="nginx/v0.1.1"
export OPENSSL_VERSION=3.4.0
export ZLIB_VERSION=1.3.1
export ABSEIL_VERSION=20240722.0
export GRPC_VERSION=1.70.1
export PROTOBUF_VERSION=3.29.0
export RE2_VERSION=2022-04-01
export CARES_VERSION=cares-1_19_1
export PCRE2_VERSION=pcre2-10.45
export SLJIT_VERSION=e51eabbfb8eabc6526f56e4e88b29fb10d1ee048
export NLOHMANNJSON_VERSION=v3.11.3

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
  bash gcc clang libc-dev make automake openssl-dev openssl-libs-static \
  pcre-dev zlib-dev zlib-static linux-headers libxslt-dev gd-dev perl-dev \
  libedit-dev mercurial alpine-sdk findutils curl curl-static ca-certificates \
  patch libaio-dev openssl cmake util-linux lmdb-tools wget curl-dev \
  libprotobuf git g++ pkgconf flex bison doxygen yajl-dev lmdb-dev libtool \
  autoconf libxml2 libxml2-dev python3 libmaxminddb-dev bc unzip dos2unix \
  yaml-cpp coreutils ninja gtest-dev git build-base pkgconfig c-ares-dev \
  re2-dev grpc-dev protobuf-dev

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
#get_src 08f40636adbc5f33d2084bd8e7b64e491dd0239d1a95021dbffbdf1ca8cea454 \
get_src 53cd32cedb27762ea2060a9c8d83e4b822de13d73b5d5d37a2db3cf55018d694 \
        "${GITHUB}/open-telemetry/opentelemetry-proto/archive/$OPENTELEMETRY_PROTO_VERSION.tar.gz" "opentelemetry-proto"
get_src a0a5e616c4a0a32e48899d12242fed5a371f69a85f11ff274a87a2f02f419876 \
        "${GITHUB}/openresty/lua-nginx-module/archive/$LUA_NGX_VERSION.tar.gz" "lua-nginx-module"
get_src ecf5c2afd345149cef19bf2e3e196bf1c514ca85e778f853f80a379284b70de1 \
        "${GITHUB}/openresty/stream-lua-nginx-module/archive/$LUA_STREAM_NGX_VERSION.tar.gz" "stream-lua-nginx-module"
get_src 2a69815e4ae01aa8b170941a8e1a10b6f6a9aab699dee485d58f021dd933829a \
        "${GITHUB}/openresty/lua-upstream-nginx-module/archive/$LUA_UPSTREAM_VERSION.tar.gz" "lua-upstream-nginx-module"
get_src 3b269f3a55c420e5a286bbd6b8ef8a5425dbcb4194fa2beb9e22eea277cd6638 \
        "${GITHUB}/openresty/luajit2/archive/$LUAJIT_VERSION.tar.gz" "luajit2"
get_src adc7781ddaeab9341b82033a6c06b0d190d4c6d1c2dddd46f6965ce9e57a0310 \
        "${GITHUB}/openresty/lua-resty-core/archive/$LUA_RESTY_CORE.tar.gz" "lua-resty-core"
get_src 8cf1a22e0d5b8f35cb0b2e14c58fcb3aa505a8fb6e956817f0cdb1f06593f072 \
        "${GITHUB}/openresty/lua-resty-lrucache/archive/$LUA_RESTY_CACHE.tar.gz" "lua-resty-lrucache"
get_src dd8ff701691f19bf4e225d42ef0d3d5e6ca0e03498ee4f044a0402e4697e4a20 \
        "${GITHUB}/microsoft/mimalloc/archive/${MIMALOC_VERSION}.tar.gz" "mimalloc"
get_src b16c9c33ed6f3f88e71a6d2dbcb2ad9f67373f566bcbbccb75d7a9fe930a062f \
        "${GITHUB}/open-telemetry/opentelemetry-cpp-contrib/archive/${OPENTELEMETRY_CONTRIB_VERSION}.tar.gz" "opentelemetry-cpp-contrib"
get_src e15dda82fe2fe8139dc2ac21a36d4ca01d5313c75f99f46c4e8a27709b7294bf \
        "${GITHUB}/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" "openssl"
get_src 9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23 \
        "http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz" "zlib"
get_src f50e5ac311a81382da7fa75b97310e4b9006474f9560ac46f54a9967f07d4ae3 \
        "${GITHUB}/abseil/abseil-cpp/archive/refs/tags/${ABSEIL_VERSION}.tar.gz" "abseil"
get_src c4e85806a3a23fd2a78a9f8505771ff60b2beef38305167d50f5e8151728e426 \
        "${GITHUB}/grpc/grpc/archive/v${GRPC_VERSION}.tar.gz" "grpc"
get_src 4e8515793ab052d0e2e8ce4269bc69afbfd358b2bdb2faadaac03a1cea028ad1 \
        "${GITHUB}/protocolbuffers/protobuf/archive/refs/tags/v${PROTOBUF_VERSION}.tar.gz" "protobuf"
#get_src edfb2be2b7068d9f4f15fcaac2fdd506ec823889da266a2d07c421ebd2135865  "${GITHUB}/nginxinc/nginx-otel/archive/refs/tags/v${NGINX_OTEL_VERSION}.tar.gz" "nginx-otel"
get_src 41d36c28298de97dd660fa3f21883c2e281b48c4b52bfc813df8c4fb6e00e798         "${GITHUB}/nginxinc/nginx-otel/archive/${NGINX_OTEL_VERSION}.tar.gz" "nginx-otel"
get_src 1ae8ccfdb1066a731bba6ee0881baad5efd2cd661acd9569b689f2586e1a50e9 \
        "${GITHUB}/google/re2/archive/refs/tags/${RE2_VERSION}.tar.gz" "re2"
get_src 9eadec0b34015941abdf3eb6aead694c8d96a192a792131186a7e0a86f2ad6d9 \
        "${GITHUB}/c-ares/c-ares/archive/refs/tags/${CARES_VERSION}.tar.gz" "c-ares"
get_src 35ce7d21f511c4a81d7079164077d25fbc41af00f19e1b547801df905c5f0fab \
        "${GITHUB}/PCRE2Project/pcre2/archive/refs/tags/${PCRE2_VERSION}.tar.gz" "pcre2"
get_src 5caf31959f4c2dfa9fdbaf290b0e16538527d929d5c1c5bd1a3e6df01436c1cf \
       "${GITHUB}/zherczeg/sljit/archive/${SLJIT_VERSION}.tar.gz" "sljit"
get_src 0d8ef5af7f9794e3263480193c491549b2ba6cc74bb018906202ada498a79406 \
       "${GITHUB}/nlohmann/json/archive/${NLOHMANNJSON_VERSION}.tar.gz" "nlohmannjson"

# improve compilation times
CORES=$(($(grep -c ^processor /proc/cpuinfo) - 1))
export MAKEFLAGS=-j${CORES}
export CTEST_BUILD_FLAGS=${MAKEFLAGS}
#export CFLAGS="-static"
#  CXXFLAGS="-static" CPPFLAGS="-static"

# Install luajit from openresty fork
export LUAJIT_LIB=/usr/local/lib
export LUA_LIB_DIR="$LUAJIT_LIB/lua"
export LUAJIT_INC=/usr/local/include/luajit-2.1

cd "$BUILD_PATH/zlib" && ./configure --prefix=/usr --static && make && make install
cd "$BUILD_PATH/openssl" && ./config --prefix=/usr --openssldir=/etc/ssl no-docs no-shared no-pinshared && make && make install
cd "$BUILD_PATH/pcre2" && mv "$BUILD_PATH/sljit" deps/ && ./configure --prefix=/usr --enable-jit --enable-static && make && make install
cd "$BUILD_PATH/luajit2" && CFLAGS="-static" make CCDEBUG=-g && make install
ln -s /usr/local/bin/luajit /usr/local/bin/lua
ln -s "$LUAJIT_INC" /usr/local/include/lua

	export CMAKE_PREFIX_PATH=/usr/local && \
	cd "$BUILD_PATH/abseil" && mkdir build && cd build && \
	cmake ${CMAKE_COMMON} -DBUILD_TESTING=OFF ../ && \
	make -j$(nproc) install && \
    cd "$BUILD_PATH/re2" && mkdir build && cd build && \
    sed -i '/stringpiece.h/a#include <cstdint>' ../util/pcre.h && \
    cmake ${CMAKE_COMMON} -DBUILD_TESTING=OFF .. && \
    make -j$(nproc) install && \
	cd "$BUILD_PATH/protobuf" && mkdir build && cd build && \
#rm -rf build && sed -i '/APPEND _protobuf_libraries libupb/d' cmake/install.cmake && cmake -B build -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_ABSL_PROVIDER=package -DCMAKE_BUILD_TYPE=Release -DZLIB_LIBRARY_RELEASE=/usr/lib/libz.a -Dprotobuf_BUILD_LIBPROTOC=ON && cd build && make -j$(nproc) install
	cmake ${CMAKE_COMMON} -Dprotobuf_BUILD_TESTS=OFF \
      -Dprotobuf_ABSL_PROVIDER=package .. && \
	make -j$(nproc) install && \
    cd "$BUILD_PATH/c-ares" && mkdir build && cd build && \
    cmake ${CMAKE_COMMON} -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCARES_STATIC=On \
      -DCARES_SHARED=Off \
      -DCARES_STATIC_PIC=On .. && \
    make -j$(nproc) install && \
	cd "$BUILD_PATH/grpc" && mkdir build && cd build && \
	CXXFLAGS='-Wno-error=format-security -Wno-attributes -DGRPC_NO_XDS -DGRPC_NO_RLS' \
      cmake ${CMAKE_COMMON} -DCMAKE_INSTALL_PREFIX=/usr \
        -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF \
		-DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF \
		-DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF \
		-DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF \
		-DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF \
		-DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF \
		-DgRPC_BUILD_CODEGEN=OFF \
		-DgRPC_SSL_PROVIDER=package \
		-DgRPC_RE2_PROVIDER=package \
		-DgRPC_ZLIB_PROVIDER=package \
		-DgRPC_CARES_PROVIDER=package \
		-DgRPC_ABSL_PROVIDER=package \
		-DgRPC_PROTOBUF_PROVIDER=package \
        -DgRPC_INSTALL=ON \
        -DgRPC_BUILD_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
		-DgRPC_USE_PROTO_LITE=ON ../ && \
	make -j$(nproc) install # && \ cd /tmp/opentelemetry-cpp-${OPENTELEMETRY_CPP_VERSION} && mkdir build && cd build && \ cmake ${CMAKE_COMMON} -DBUILD_TESTING=OFF -DWITH_ABSEIL=OFF \ -DWITH_BENCHMARK=OFF -DWITH_EXAMPLES=OFF ../ && \ make -j$(nproc) install
    cd "$BUILD_PATH/nlohmannjson" && \
    cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF && \
    cmake --build build && \
    cmake --install build

cd "$BUILD_PATH/opentelemetry-cpp"
export CXXFLAGS="-DBENCHMARK_HAS_NO_INLINE_ASSEMBLY"
cmake -B build -G Ninja -Wno-dev \
        -DOTELCPP_PROTO_PATH="${BUILD_PATH}/opentelemetry-proto/" \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DBUILD_TESTING=OFF \
        -DWITH_BENCHMARK=OFF \
        -DBUILD_W3CTRACECONTEXT_TEST="OFF" \
        -DCMAKE_BUILD_TYPE=Release \
        -DWITH_ABSEIL=ON \
        -DWITH_STL=ON \
        -DWITH_EXAMPLES=OFF \
        -DWITH_OTLP_GRPC=OFF \
        -DWITH_OTLP_HTTP=ON \
        -DWITH_ZIPKIN=ON \
        -DWITH_PROMETHEUS=OFF \
        -DWITH_ASYNC_EXPORT_PREVIEW=OFF \
        -DWITH_METRICS_EXEMPLAR_PREVIEW=OFF \
        -DBUILD_SHARED_LIBS=OFF
      cmake --build build
      cmake --install build

# Git tuning
git config --global --add core.compression -1

export NGX_OTEL_PROTO_DIR="$BUILD_PATH/opentelemetry-proto"
export NGX_OTEL_CMAKE_OPTS="-DNGX_OTEL_GRPC=package -DNGX_OTEL_SDK=package -DNGX_OTEL_PROTO_DIR=$NGX_OTEL_PROTO_DIR"
export USE_LUAJIT=1
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1

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

#export LDFLAGS="-static" CFLAGS="-static"

WITH_FLAGS=" --with-pcre-jit \
  --with-compat \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_realip_module \
  --with-http_gzip_static_module \
  --with-http_sub_module \
  --with-stream \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_ssl_preread_module \
  --with-threads \
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

LD_OPT=""
#LD_OPT="-static -fPIE -fPIC -pie -Wl,-z,relro -Wl,-z,now"

if [[ ${ARCH} != "aarch64" ]]; then
  WITH_FLAGS+=" --with-file-aio"
fi

if [[ ${ARCH} == "x86_64" ]]; then
  CC_OPT+=' -m64 -mtune=generic'
fi

WITH_MODULES=" \
  --add-module=$BUILD_PATH/ngx_devel_kit \
  --add-module=$BUILD_PATH/lua-nginx-module \
  --add-module=$BUILD_PATH/stream-lua-nginx-module \
  --add-module=$BUILD_PATH/lua-upstream-nginx-module \
  --add-module=$BUILD_PATH/opentelemetry-cpp-contrib/instrumentation/nginx"

CFLAGS='-static -s' LDFLAGS=-static ./configure \
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
 
#export OTEL_TEMP_INSTALL=/tmp/otel
#mkdir -p ${OTEL_TEMP_INSTALL}
#
#cd ${BUILD_PATH}/opentelemetry-cpp-contrib/instrumentation/nginx
#mkdir -p build
#cd build
#        #-DBUILD_SHARED_LIBS=ON \
#cmake -DCMAKE_BUILD_TYPE=Release \
#        -G Ninja \
#        -DCMAKE_CXX_STANDARD=17 \
#        -DCMAKE_INSTALL_PREFIX=${OTEL_TEMP_INSTALL} \
#        -DNGINX_VERSION=${NGINX_VERSION} \
#        ..
#cmake --build . -j ${CORES} --target install
#
#mkdir -p /etc/nginx/modules
#cp ${OTEL_TEMP_INSTALL}/otel_ngx_module.so /etc/nginx/modules/otel_ngx_module.so


cd "$BUILD_PATH/lua-resty-core"
make install

export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1
ln -s $LUA_INCLUDE_DIR /usr/include/lua5.1

cd "$BUILD_PATH/lua-resty-lrucache"
make install

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
  /var/log/audit \
  /var/log/nginx \
);

adduser -S -D -H -u 101 -h /usr/local/nginx -s /sbin/nologin -G www-data -g www-data www-data

for dir in "${writeDirs[@]}"; do
  mkdir -p ${dir};
  chown -R www-data:www-data ${dir};
done

# remove .a files
find /usr/local -name "*.a" -print | xargs /bin/rm
