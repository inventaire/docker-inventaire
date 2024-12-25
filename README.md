Run [Inventaire](https://github.com/inventaire/inventaire) in Docker

This repository is packaging Inventaire for Docker production environement. To run it for production outside Docker, see [inventaire-deploy](https://github.com/inventaire/inventaire-deploy).

You may also check the official [Docker image](https://hub.docker.com/repository/docker/inventaire/inventaire/general)

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

Set the email server by editing the file `config/local-production.cjs`. For example:

```js
mailer: {
  disabled: false,
  nodemailer: {
    host: 'smtp.an-email-provider.net',
    port: 587,
    auth: {
      user: 'user',
      pass: 'password'
    },
  },
},
```

## Reverse proxy configuration

Generate the first SSL certificate with Let's Encrypt

```sh
docker run -it --rm --name certbot -p 80:80 -v "$(pwd)/certbot/conf:/etc/letsencrypt" certbot/certbot certonly --standalone
```

## Usage

Start CouchDB, Elasticsearch, Nginx and the Inventaire [server](https://github.com/inventaire/inventaire) in production mode
```sh
docker-compose up
```

Go to the sign up page (`https://DOMAIN_NAME/signup`) and create a user

Make the newly created user an admin (replace `your_username` in the command below by the user username) :

```sh
docker exec $(docker ps -f name=_inventaire --format "{{.ID}}") npm run db-actions:update-user-role-from-username your_username add admin
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

`docker exec $(docker ps -f name=couchdb --format "{{.ID}}") curl  -H 'Content-Type:application/json' -H 'Accept: application/json' -XPUT "http://couchdb:password@localhost:5984/_users"`

