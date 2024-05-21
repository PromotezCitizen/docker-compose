#!/bin/bash

DOCKER_APP_NAME=prod
COMPOSE_PATH=compose/

LAST=$(docker ps -f "name=${DOCKER_APP_NAME}-blue" -f "name=${DOCKER_APP_NAME}-green" --format "{{.Names}}" | awk -F '-' '{print $2}')
echo ${LAST} > last

docker compose -p ${DOCKER_APP_NAME}-${LAST} -f "${COMPOSE_PATH}docker-compose.${LAST}.yml" down
docker compose -p ${DOCKER_APP_NAME} -f "${COMPOSE_PATH}docker-compose.yml" down