ARG PHP_VERSION
FROM ${PHP_VERSION}

ARG TZ
ARG PHP_EXTENSIONS
ARG CONTAINER_PACKAGE_URL


RUN if [ $CONTAINER_PACKAGE_URL ] ; then sed -i "s/dl-cdn.alpinelinux.org/${CONTAINER_PACKAGE_URL}/g" /etc/apk/repositories ; fi


COPY ./php/extensions /tmp/extensions
WORKDIR /tmp/extensions
RUN chmod +x install.sh \
    && sh install.sh \
    && rm -rf /tmp/extensions

ADD ./php/extensions/install-php-extensions  /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions

RUN apk --no-cache add tzdata \
    && cp "/usr/share/zoneinfo/$TZ" /etc/localtime \
    && echo "$TZ" > /etc/timezone


# Fix: https://github.com/docker-library/php/issues/240
RUN apk add gnu-libiconv libstdc++ --no-cache --repository http://${CONTAINER_PACKAGE_URL}/alpine/edge/community/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php


# Install composer and change it's cache home
RUN curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x /usr/bin/composer
ENV COMPOSER_HOME=/tmp/composer

# php image's www-data user uid & gid are 82, change them to 1000 (primary user)
RUN apk --no-cache add shadow && usermod -u 1000 www-data && groupmod -g 1000 www-data

# 安装swoole_loader扩展
ARG PHP_EXT_SWOOLE_LOADER
ADD ${PHP_EXT_SWOOLE_LOADER} /
RUN chmod a+x /swoole_loader.so && \
    cp -f /swoole_loader.so /usr/local/lib/php/extensions/no-debug-* && \
    echo "extension=swoole_loader.so" > /usr/local/etc/php/conf.d/docker-php-ext-swoole_loader.ini

# 安装nginx
RUN mkdir /www
ADD ./nginx/conf.d/localhost.conf /
ADD ./nginx/ssl /ssl
ADD ./nginx/fastcgi_params /
ADD ./nginx/fastcgi-php.conf /
ADD ./nginx/nginx.conf /
ADD ./www/index.html /
ADD ./www/test.php /
ADD ./run.sh /
RUN apk update && apk add nginx && \
    apk add vim m4 autoconf make gcc g++ linux-headers && \
    mkdir /run/nginx && \
    mv /nginx.conf /etc/nginx/nginx.conf && \
    mv -f /localhost.conf /etc/nginx/conf.d/default.conf && \
    mv /ssl / && \
    mv /fastcgi_params /etc/nginx/fastcgi_params && \
    mv /fastcgi-php.conf /etc/nginx/fastcgi-php.conf && \
    mv /index.html /www && \
    mv /test.php /www && \
    touch /run/nginx/nginx.pid && \
    chmod 755 /run.sh && \
    apk del m4 autoconf make gcc g++ linux-headers
EXPOSE 9000
ENTRYPOINT ["/run.sh"]

WORKDIR /www
