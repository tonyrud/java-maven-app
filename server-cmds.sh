#!/usr/bin/env bash


export IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PASS=$3

echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin ${DOCKER_REPO_SERVER}
docker-compose -f docker_compose.yml up --detach
echo "success"
