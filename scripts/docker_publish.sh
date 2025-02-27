#!/usr/bin/env bash

set -eu

cwd="$PWD"

cd ./inventaire

echo -n "Enter version number (ex: 3.0.0-beta): "
read -r version

docker build -t inventaire -f ./Dockerfile.inventaire .

docker tag inventaire "inventaire/inventaire:${version}"
docker tag inventaire inventaire/inventaire:latest

docker push "inventaire/inventaire:${version}"
docker push inventaire/inventaire:latest

cd "$cwd"
