Run [Inventaire](https://github.com/inventaire/inventaire) in Docker

This repository is meant to support running Inventaire for testing and development. For production, see [inventaire-deploy](https://github.com/inventaire/inventaire-deploy).

## Summary

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Tips](#tips)
  - [Fixtures](#fixtures)
  - [Tests](#tests)
  - [Push git commits](#push-git-commits)
  - [Rootless Docker](#rootless-docker)
  - [Run inventaire server and client outside of Docker](#run-inventaire-server-and-client-outside-of-docker)
- [Troubleshooting](#troubleshooting)
  - [Elasticsearch errors](#elasticsearch-errors)
  - [Quieting CouchDB notice](#quieting-couchdb-notice)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Requirements

- [docker-compose](https://docs.docker.com/compose/gettingstarted/) up and ready
- git

## Install

```sh
git clone https://github.com/inventaire/docker-inventaire.git
cd docker-inventaire
```

Rename `dotenv` file to `.env`, and customize the variables (mainly adding the domain name, and a couchdb password):

```sh
cp dotenv .env
vim .env
```

Clone `inventaire` core application [server](https://github.com/inventaire/inventaire)

```sh
git clone https://github.com/inventaire/inventaire.git
```

Build

```sh
docker-compose build
```

Download Node dependencies and install the [client repository](https://github.com/inventaire/inventaire-client):

```sh
cd inventaire
npm install tsx && npm install
cd ..
```

Configure inventaire so that it can connect to CouchDB. For that, create a file `config/local.cjs` with the following command:

```sh
echo "module.exports = {
  db: {
    hostname: 'couchdb',
    username: '$(grep 'COUCHDB_USER' .env | sed -E 's/.*=//')',
    password: '$(grep 'COUCHDB_PASSWORD' .env | sed -E 's/.*=//')'
  },
  elasticsearch: {
    origin: 'http://elasticsearch:9200',
  },
  publicHostname: '$(grep 'DOMAIN_NAME' .env | sed -E 's/.*=//')',
}
" > ./inventaire/config/local-production.cjs
```

## Webserver

Generate the first SSL certificate with Let's Encrypt

```sh
sudo docker run -it --rm --name certbot -p 80:80 -v "$(pwd)/certbot/conf:/etc/letsencrypt" certbot/certbot certonly --standalone
```

## Usage

Start CouchDB, Elasticsearch, and the Inventaire [server](https://github.com/inventaire/inventaire) in production mode
```sh
docker-compose up
```

## Tips

General tips on how to run Inventaire can be found in the [server repository docs](https://github.com/inventaire/inventaire/tree/main/docs). Here after are some additional Docker-specific tips.

### Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs (see Tests section)

```sh
docker-compose -f docker-compose.yml -f docker-compose.test.yml exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```sh
`docker-compose exec inventaire npm run replicate-tests-db`
```

### Tests

Start services with test environnement with [multiple compose files](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files)

```sh
docker-compose -f docker-compose.yml -f docker-compose.test.yml up
```

Execute tests script

```sh
docker-compose exec inventaire npm run test-api
```

or execute directly the test command

```sh
docker-compose exec inventaire npm test /opt/inventaire/path/to/test/file
```

Tip : create a symbolic link on your machine between the inventaire folder and docker working directory on your machine at `/opt/`, in order to autocomplete path to test file to execute

```sh
sudo ln ~/path/to/inventaire-docker/inventaire /opt -s
```

Alternatively, as root in inventaire container:

```sh
mkdir /supervisor/path/to/inventaire
ln -s /opt/ /supervisor/path/to/inventaire
```

### Push git commits

To keep things simple, this installation steps above clone repositories in https, but if you want to push to a branch with ssh, you will probably need to change the repositories `origin`:
```sh
cd inventaire
git remote set-url origin git@github.com:inventaire/inventaire.git
cd client
git remote set-url origin git@github.com:inventaire/inventaire-client.git
```

### Rootless Docker

Docker Engine v20.10 is now available in rootless mode. If you would like to try it, you may follow the [official guide](https://docs.docker.com/engine/security/rootless/) (including command `export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock`).

Start the inventaire install steps above, before installing dependencies, make sure that the owner of inventaire folder is the same as the owner inside the container.

Delete `network_host` occurences from `docker-compose.yml` and adapt the `config/local.cjs` in consequence:

```js
module.exports = {
  protocol: 'http',
  port: 3006,
  host: 'inventaire',
  db: {
    username: 'couchdb',
    password: 'password',
    protocol: 'http',
    hostname: 'couch'
  },
  elasticsearch: {
    host:'http://elasticsearch:9200'
  }
}
```

### Run inventaire server and client outside of Docker

It can sometimes be more convenient to keep CouchDB and Elasticsearch in Docker, but to run the Inventaire server and client outside. For this you will need to:
- have [NodeJS](https://nodejs.org/) >= v16 installed on your machine, which should make both `node` and `npm` executables accessible in your terminal

Then you can start CouchDB and Elasticsearch in the background
```sh
docker-compose up couchdb elasticsearch -d
```

Start the Inventaire server in development mode
```sh
cd inventaire
npm run watch
```

And in another terminal, start the client Webpack dev server
```sh
cd inventaire/client
npm run watch
```

## Troubleshooting

### Elasticsearch errors
- `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`: fix by running the command `sudo sysctl -w vm.max_map_count=262144` on your host machine

See also [Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/docker.html)

### Quieting CouchDB notice
CouchDB may warn constantly that `_users` database does not exist, [as documented](https://docs.couchdb.org/en/latest/setup/single-node.html), you can create de database with:

`curl -X PUT http://127.0.0.1:5984/_users`
