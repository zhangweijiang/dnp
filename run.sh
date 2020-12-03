#!/bin/sh

# 后台启动
PIDS=`ps -ef|grep "php-fpm"`

if [ "$PIDS" != "" ]; then
pkill -9 php-fpm
php-fpm -D
echo "php-fpm restart"
else
php-fpm -D
echo "php-fpm start"
fi
# 关闭后台启动，hold住进程
nginx -g 'daemon off;'
