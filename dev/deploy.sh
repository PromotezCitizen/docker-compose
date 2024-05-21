#!/bin/bash

docker pull han990401/rgback-dev

DOCKER_APP_NAME="dev"

EXIST_BLUE=$(docker compose -p ${DOCKER_APP_NAME}-blue -f compose/docker-compose.blue.yml ps | grep Up)
# -z: 0, -n: 1 이상
if [ -z "$EXIST_BLUE" ]; then # green이 동작되고 있을 경우, 즉 blue의 결과가 ""인 경우
  docker compose -p ${DOCKER_APP_NAME}-blue -f compose/docker-compose.blue.yml up -d
  BEFORE_COMPOSE_COLOR="green";
  AFTER_COMPOSE_COLOR="blue";
  AFTER_PORT=18000
  echo "deploy dev blue"
else # blue가 동작되고 있을 경우
  docker compose -p ${DOCKER_APP_NAME}-green -f compose/docker-compose.green.yml up -d
  BEFORE_COMPOSE_COLOR="blue";
  AFTER_COMPOSE_COLOR="green";
  AFTER_PORT=18001
  echo "deploy dev green"
fi

while [ 1 == 1 ]
do
  IS_UP_AFTER=$(docker compose -p ${DOCKER_APP_NAME}-${AFTER_COMPOSE_COLOR} -f compose/docker-compose.${AFTER_COMPOSE_COLOR}.yml ps | grep Up)
  if [ -n "$IS_UP_AFTER" ]; then
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 1 localhost:${AFTER_PORT})
    QUOTIENT=$((STATUS_CODE / 100))
    if [ 2 -eq ${QUOTIENT} ]; then
      echo "Deploy SUCCESS!"
      break
    fi
  fi
  
  sleep 1
done
EXIST_AFTER=$(docker compose -p ${DOCKER_APP_NAME}-${AFTER_COMPOSE_COLOR} -f compose/docker-compose.${AFTER_COMPOSE_COLOR}.yml ps)

if [ -n "$EXIST_AFTER" ]; then
  cp nginx/nginx.${AFTER_COMPOSE_COLOR}.conf nginx/nginx.conf
  docker exec ${DOCKER_APP_NAME}-nginx nginx -s reload

  docker compose -p ${DOCKER_APP_NAME}-${BEFORE_COMPOSE_COLOR} -f compose/docker-compose.${BEFORE_COMPOSE_COLOR}.yml down
  echo "dev ${BEFORE_COMPOSE_COLOR} down"
fi

docker image prune -f
