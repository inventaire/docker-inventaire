# Inventaire Suite

The Inventaire Suite is a containerized, production-ready Inventaire system that allows you to self-host a knowledge graph similar to [inventaire.io](https://inventaire.io).

It is composed of several services:
* **[Inventaire](https://hub.docker.com/r/inventaire/inventaire)**: a Docker image packaging:
  * the Inventaire [server](https://github.com/inventaire/inventaire/)
  * the [client](https://github.com/inventaire/inventaire-client/)
  * the in-memory database: LevelDB
* **[CouchDB](https://hub.docker.com/_/couchdb)**: the primary database used by the Inventaire server
* **[Elasticsearch](https://hub.docker.com/_/elasticsearch)**: a secondary database used by Inventaire for text and geographic search features
* **[Nginx](https://hub.docker.com/_/nginx)**: a reverse proxy with TLS termination thank to Let's Encrypt [certbot](https://hub.docker.com/r/certbot/certbot).

The service orchestration is implemented using Docker Compose.

> 🔧 This document is for people wanting to self-host the full Inventaire Suite. If you are looking for the individual Inventaire image, head over to [hub.docker.com/r/inventaire/inventaire](https://hub.docker.com/r/inventaire/inventaire).

> 💡 This document presumes familiarity with basic Linux administration tasks and with Docker and Docker Compose.

## Summary

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Requirements](#requirements)
- [Install](#install)
- [Reverse proxy configuration](#reverse-proxy-configuration)
- [Usage](#usage)
- [Tips](#tips)
  - [Fixtures](#fixtures)
  - [Path autocomplete](#path-autocomplete)
  - [Run inventaire server and client outside of Docker](#run-inventaire-server-and-client-outside-of-docker)
- [Troubleshooting](#troubleshooting)
  - [Elasticsearch errors](#elasticsearch-errors)
  - [Quieting CouchDB notice](#quieting-couchdb-notice)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Quickstart
### Requirements
#### Hardware
* Network connection with a public IP address
* 4 GB RAM
* 10 GB free disk space

#### Software
* [Docker](https://docs.docker.com/get-started/get-docker/) >= v22.0
* [Docker compose](https://docs.docker.com/compose/gettingstarted/) >= v2
* [git](https://git-scm.com/)

#### Domain name
You need a DNS records that resolves to your machine's public IP address

## Initial setup

### Download this repository
```sh
git clone https://github.com/inventaire/docker-inventaire.git
cd docker-inventaire
```

### Initial configuration
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

Configure inventaire so that it can connect to CouchDB. For that, create a file `config/local-production.cjs` with the following command:

```sh
echo "module.exports = {
  db: {
    hostname: 'couchdb',
  },
  elasticsearch: {
    origin: 'http://elasticsearch:9200',
  }
}
" > ./inventaire/config/local-production.cjs
```

## Reverse proxy configuration

Inventaire only provides configuration files for Nginx.

Run dependencies:

```sh
sudo mkdir -p /tmp/nginx/tmp /tmp/nginx/resize/img/users /tmp/nginx/resize/img/groups /tmp/nginx/resize/img/entities /tmp/nginx/resize/img/remote /tmp/nginx/resize/img/assets
```

Install nginx and certbot

Copy the nginx configuration template

```sh
PUBLIC_HOSTNAME=$(grep -oP 'PUBLIC_HOSTNAME=\K.*' .env) PROJECT_ROOT=$(grep -oP 'PROJECT_ROOT=\K.*' .env) envsubst < nginx/templates/default.conf.template > nginx/default
sudo mv nginx/default /etc/nginx/sites-available/default
```

Activate the configuration file

```sh
sudo ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
```

To generate the certificate for your domain as required to make https work, you can use Let's Encrypt:

```sh
sudo systemctl stop nginx
sudo certbot certonly --standalone --post-hook "systemctl restart nginx"
sudo systemctl restart nginx
```

When certbot is done, you may uncomment lines starting with `# ssl_certificate` and `# ssl_certificate_key` in `/etc/nginx/sites-available/default.conf` and restart nginx.

Certbot should have installed a cron to automatically renew your certificate.
Since nginx template supports webroot renewal, we suggest you to update the renewal config file to use the webroot authenticator:

```sh
# Replace authenticator = standalone by authenticator = webroot
# Add webroot_path = /var/www/certbot
sudo vim /etc/letsencrypt/renewal/your-domain.com.conf
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

Run API tests to populate tests dbs

```sh
docker-compose -f docker-compose.yml exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```sh
`docker-compose exec inventaire npm run replicate-tests-db`
```

### Path autocomplete

Create a symbolic link on your machine between the inventaire folder and docker working directory on your machine at `/opt/`, in order to autocomplete path to test file to execute

```sh
sudo ln ~/path/to/inventaire-docker/inventaire /opt -s
```

Alternatively, as root in inventaire container:

```sh
mkdir /supervisor/path/to/inventaire
ln -s /opt/ /supervisor/path/to/inventaire
```

### Run inventaire server and client outside of Docker

It can sometimes be more convenient to keep CouchDB and Elasticsearch in Docker, but to run the Inventaire server and client outside. For this, you will need to have [NodeJS](https://nodejs.org/) >= v16 installed on your machine, which should make both `node` and `npm` executables accessible in your terminal

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
