#!/bin/bash

echo "## Stopping containers"
docker compose down

echo "## Starting containers"
docker compose up -d 

echo "## Start Logging"
docker-compose logs --no-color >& docker-compose.log.txt &

echo "## Running tests"
pushd rinha-de-backend-2024-q1
./executar-teste-local.sh
popd

echo "# done"
