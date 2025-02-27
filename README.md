# Inventaire Suite

The Inventaire Suite is a containerized, production-ready Inventaire system that allows you to self-host a knowledge graph similar to [inventaire.io](https://inventaire.io).

It is composed of several services:
* **[Inventaire](https://hub.docker.com/r/inventaire/inventaire)**: a Docker image packaging:
  * the Inventaire [server](https://git.inventaire.io/inventaire/), which comes with its embedded database: LevelDB
  * the Inventaire [client](https://git.inventaire.io/inventaire-client/)
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
> Ignore this section if you are just testing on your local machine

You need a DNS records that resolves to your machine's public IP address

#### Open ports
> Ignore this section if you are just testing on your local machine

Your machine's firewall should let the http ports (`80` and `443`) open.

## Initial setup

### Download this repository
```sh
git clone https://git.inventaire.io/docker-inventaire.git
cd docker-inventaire
```

### Initial configuration
Copy the `dotenv` file to `.env`
```sh
cp dotenv .env
```
and open this new `.env` file with a text editor to customize the variables (mainly adding your own domain name, and setup a couchdb password)

#### Reverse proxy configuration
> Ignore this section if you are just testing on your local machine

Generate the first TLS certificate with Let's Encrypt

```sh
docker run -it --rm --name certbot -p 80:80 -v "$(pwd)/certbot/conf:/etc/letsencrypt" certbot/certbot certonly --standalone
```

## Usage

Start all the services (Nginx, CouchDB, Elasticsearch, and the Inventaire [server](https://git.inventaire.io/inventaire)) in production mode:
```sh
docker-compose up -d
```

Alternatively, to test locally, you can start only Inventaire and its dependencies (CouchDB and Elasticsearch) without Nginx, with the following command
```sh
docker-compose up inventaire
```

## Tips

General tips on how to run Inventaire can be found in the [server repository docs](https://git.inventaire.io/inventaire/tree/main/docs). Here after are some additional Docker-specific tips.

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

## Troubleshooting

### Elasticsearch errors

- `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`: fix by running the command `sudo sysctl -w vm.max_map_count=262144` on your host machine

See also [Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/docker.html)
