#!/bin/bash
#
action="${1}"
echo
while ! nc -z $DB_HOST $DB_PORT;
do
    echo "wait for jms_mysql ${DB_HOST} ready"
    sleep 2s
done

if [ $REDIS_HOST == "127.0.0.1" ]; then
    if [[ "$(uname -m)" == "aarch64" ]]; then
        sed -i "s/# ignore-warnings ARM64-COW-BUG/ignore-warnings ARM64-COW-BUG/g" /etc/redis/redis.conf
    fi
    sed -i "s@# requirepass .*@requirepass $REDIS_PASSWORD@g" /etc/redis/redis.conf
    /etc/init.d/redis-server start
fi

while ! nc -z $REDIS_HOST $REDIS_PORT;
do
    echo "wait for jms_redis ${REDIS_HOST} ready"
    sleep 2s
done

if [ ! -f "/opt/jumpserver/config.yml" ]; then
    echo > /opt/jumpserver/config.yml
fi

if [ ! -f "/opt/jumpserver/logs/jumpserver.log" ]; then
    echo > /opt/jumpserver/logs/jumpserver.log
    chmod 644 /opt/jumpserver/logs/jumpserver.log
fi

if [ ! -d "/opt/jumpserver/data/media/replay" ]; then
   mkdir -p /opt/jumpserver/data/media/replay
   chmod 755 -R /opt/jumpserver/data/media/replay
fi

if [ ! -d "/opt/jumpserver/data/static" ]; then
    mkdir -p /opt/jumpserver/data/static
    chmod 755 -R /opt/jumpserver/data/static
fi

if [ -f "/opt/readme.txt" ]; then
  sed -i "s@Version:.*@Version: ${Version}@g" /opt/readme.txt
fi

rm -f /opt/jumpserver/tmp/*.pid

if [ -f "/etc/init.d/cron" ]; then
  /etc/init.d/cron start
fi

if [ "$action" == "upgrade" ] || [ "$action" == "init_db" ]; then
    cd /opt/jumpserver
    . /opt/py3/bin/activate
    ./jms upgrade_db || {
        echo -e "\033[31m 数据库处理失败, 请根据错误排查问题. \033[0m"
        exit 1
   }
   exit 0
fi

echo
echo "Time: $(date "+%Y-%m-%d %H:%M:%S")"
if [ -f "/opt/readme.txt" ]; then
  cat /opt/readme.txt
  rm -f /opt/readme.txt
fi
echo
echo "LOG_LEVEL: ${LOG_LEVEL}"
echo "JumpServer Logs:"

/etc/init.d/nginx start
/etc/init.d/supervisor start
