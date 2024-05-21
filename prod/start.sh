#!/bin/bash

DOCKER_APP_NAME=prod

# 이전에 마지막으로 켰던 컨테이너 확인
LAST=$(cat last)
if [ -z "$FLAG" ]; then
  cat blue > last;
  FLAG='blue'
fi

# default conf로 덮어쓰기
cp nginx/nginx.default.conf nginx/nginx.conf

# nginx와 database만 먼저 실행
docker compose -p ${DOCKER_APP_NAME} -f compose/docker-compose.yml up -d

# 서버 green || blue 실행
docker compose -p ${DOCKER_APP_NAME}-${LAST} -f compose/docker-compose.${LAST}.yml up -d

if [ "$FLAG" == 'blue' ]; then
  SERVER_PORT=8000
else
  SERVER_PORT=8001
fi

while [ 1 == 1 ]
do
  IS_UP_AFTER=$(docker compose -p ${DOCKER_APP_NAME}-${LAST} -f compose/docker-compose.${LAST}.yml ps | grep Up)
  if [ -n "$IS_UP_AFTER" ]; then
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 1 localhost:${SERVER_PORT})
    QUOTIENT=$((STATUS_CODE / 100))
    if [ 2 -eq ${QUOTIENT} ]; then
      echo "SUCCESS!"
      break
    fi
  fi
  
  sleep 1
done

# nginx 설정 복사
cp nginx/nginx.${LAST}.conf nginx/nginx.conf

# nginx 설정 reload
NGINX=$(docker ps -qf "name=${DOCKER_APP_NAME}-nginx")
docker exec ${NGINX} nginx -s reload