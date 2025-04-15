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

- [Quickstart](#quickstart)
  - [Requirements](#requirements)
    - [Hardware](#hardware)
    - [Software](#software)
    - [Domain name](#domain-name)
    - [Open ports](#open-ports)
- [Initial setup](#initial-setup)
  - [Download this repository](#download-this-repository)
  - [Initial configuration](#initial-configuration)
    - [Generate a TLS certificate](#generate-a-tls-certificate)
- [Usage](#usage)
- [Update](#update)
- [Tips](#tips)
- [Troubleshooting](#troubleshooting)
  - [Elasticsearch errors](#elasticsearch-errors)

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

#### Generate a TLS certificate
> Ignore this section if you are just testing on your local machine

Generate the first TLS certificate with Let's Encrypt

```sh
docker run -it --rm --name certbot -p 80:80 -v "$(pwd)/certbot/conf:/etc/letsencrypt" certbot/certbot certonly --standalone
```

## Usage

Start all the services (Nginx, CouchDB, Elasticsearch, and the Inventaire [server](https://git.inventaire.io/inventaire)) in production mode:
```sh
docker compose up --detach
```

Alternatively, to test locally, you can start only Inventaire and its dependencies (CouchDB and Elasticsearch) without Nginx, with the following command:
```sh
docker compose up inventaire
```

## Update

Before updating to the latest version, check that there are no breaking changes.
You can find your current version number by visiting fetching the URL `/api/config` on your domain (example: https://inventaire.io/api/config).
You can find details about the changes since your version on this page: /home/maxlath/code/inventaire/inventaire/CHANGELOG.md.
For changes marked to require data transformation, [some knowledge of CouchDB is recommended](https://docs.couchdb.org/en/stable/intro/index.html), as well as familiarizing yourself with the [recommanded way to export, transform and reimport data in CouchDB](https://github.com/inventaire/inventaire/blob/main/docs/administration/couchdb_data_transformations.md).

```sh
cd docker-inventaire
# Pull updates to this repository (might include database versions updates, and such)
git pull origin main
# Pull the updated images
docker compose pull
# Stop and remove the previous containers
docker compose down
# Remove the volume hosting inventaire server and client code, to let it be overriden by the updated inventaire image
docker volume rm docker-inventaire_inventaire-server
# Restart containers with the new image (with the --detach option, to be able to close the terminal)
docker compose up --detach
# Check that it restarted without errors
docker compose logs --follow --tail 500 inventaire
```

## Tips

General tips on how to run Inventaire can be found in the [server repository docs](https://git.inventaire.io/inventaire/tree/main/docs).

## Troubleshooting

### Elasticsearch errors

- `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`: fix by running the command `sudo sysctl -w vm.max_map_count=262144` on your host machine

See also [Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/docker.html)
