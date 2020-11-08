FROM alpine:latest

LABEL maintainer="NGINX-MEDIA_SERVER maintainer <woonizzooni@gmail.com>"

# versions of nginx and nginx-rtmp-module to use
ENV NGINX_VERSION 1.18.0
ENV RTMP_MODULE_VERSION 1.2.1

RUN set -x \
# create nginx user/group 
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
# install binaries & other dependencies from the published packaging sources
    && apk --no-cache add gcc libc-dev linux-headers pcre-dev zlib-dev ca-certificates openssl libressl-dev make \
    && rm -rf /var/cache/apk/*

# create working directory to build packages then go into.
RUN mkdir -p /tmp/build && cd /tmp/build

# download & decompress nginx & nginx-rtmp-module .tar.gz(gzipped tarball)
RUN wget -O nginx-${NGINX_VERSION}.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    wget -O nginx-rtmp-module-${RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxf nginx-rtmp-module-${RTMP_MODULE_VERSION}.tar.gz

# build and install nginx with nginx-rtmp-module, clear working directory after build
# Edit this line if you want to add more modules or change options.
RUN cd nginx-${NGINX_VERSION} && \
    ./configure \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/lock/nginx/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/tmp/nginx-client-body \
    --with-http_ssl_module \
    --with-cc-opt="-Wimplicit-fallthrough=0" \
    --with-file-aio \
    --with-threads \
    --add-module=../nginx-rtmp-module-${RTMP_MODULE_VERSION} && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    mkdir /var/lock/nginx && \
# clear working directory after build
    rm -rf /tmp/build

# forward access and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# copy local nginx.conf to docker 
COPY nginx.conf /etc/nginx/nginx.conf

# export 1935 for rtmp, 8080 for hls or dash
EXPOSE 1935 8080

CMD ["nginx", "-g", "daemon off;"]
