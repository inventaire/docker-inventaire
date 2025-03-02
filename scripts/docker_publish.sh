#!/usr/bin/env bash

set -eu

cwd="$PWD"

cd ./inventaire

version=$(curl -s https://api.github.com/repos/inventaire/inventaire/tags | jq -r '.[].name' | head -n1 | sed 's/^v//')

echo -e "Latest version number found: \e[0;32m${version}\e[0m"

response=0
while [ "$response" != "" ] && [ "$response" != "y" ] && [ "$response" != "n" ]; do {
  echo -n "Confirm: Y/n? "
  read -r response
}; done

if [ "$response" == "n" ]; then
  echo -n "Enter version number (ex: 3.0.0-beta): "
  read -r version
fi

docker build -t inventaire -f ./Dockerfile.inventaire --build-arg "GIT_REF=v${version}" .

docker tag inventaire "inventaire/inventaire:${version}"
docker tag inventaire inventaire/inventaire:latest

docker push "inventaire/inventaire:${version}"
docker push inventaire/inventaire:latest

cd "$cwd"
