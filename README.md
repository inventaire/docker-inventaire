Run your own inventaire in a docker environment
Used only for testing and development purposes, so use in production at your own risk.

## Requirements

- [docker-compose](https://docs.docker.com/compose/gettingstarted/) up and ready
- git

## Install

```sh
git clone https://github.com/inventaire/docker-inventaire.git
```

got to `cd docker-inventaire`

clone `inventaire` core application server -> [setup](https://github.com/inventaire/inventaire#installation)

```sh
git clone https://github.com/inventaire/inventaire.git
```

Build

```sh
docker-compose build
```

Download Node dependencies:

```sh
docker-compose run --rm inventaire npm install
```

Configure inventaire so that it can connect to CouchDB:

```sh
echo "module.exports = {
  db: {
    username: 'couchdb',
    password: 'password'
  }
}
" > ./inventaire/config/local.cjs
```

### Rootless Docker

Docker Engine v20.10 is now available in rootless mode. If you would like to try it, you may follow the [official guide](https://docs.docker.com/engine/security/rootless/) (including command `export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock`).

Start the inventaire install steps above, before installing dependencies, make sure that the owner of inventaire folder is the same as the owner inside the container.

Delete `network_host` occurences from `docker-compose.yml` and adapt the `config/local.js` in consequence:

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

## Usage

```sh
docker-compose up -d
```

## Create a user admin

A user admin is not that useful in development, it only allows you to merge/delete entities, see any user contributions, and a few more things. But if needed, start by signing up a user :

```sh
curl http://localhost:3006/api/auth?action=signup -d '{"username": "yourusername", "password": "yourpassword", "email":"some+email@example.org"}'
```

Grab the new user id

```sh
user_id=$(curl --user yourusername:yourpassword  http://localhost:3006/api/user | jq -r '._id')
```

Then you can either go to CouchDB GUI to manually add the `"admin": true` flag to your user document:

```sh
firefox "http://localhost:5984/_utils/document.html?users/${user_id}"
```

Or use the dedicated script, but you need to modify your local config to override the default `.db.actionsScripts` values:

```js
module.exports = {
  db: {
    actionsScripts: {
      port: 5984,
      suffix: null
    }
  }
}
```

```sh
./scripts/actions/make_user_admin_from_id.coffee $user_id
```

## Load wikidata entities into elasticsearch

Elasticsearch import limit may be below the indexation import rate

```sh
curl -XPOST http://localhost:9200/wikidata/_close
curl -H 'Content-Type:application/json' -H 'Accept: application/json' -XPUT http://localhost:9200/wikidata/_settings -d '{"index.mapping.total_fields.limit": 20000}'
curl -XPOST http://localhost:9200/wikidata/_open
```

## Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs (see Tests section)

```sh
docker-compose -f docker-compose.yml -f docker-compose.test.yml exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```sh
`docker-compose exec inventaire npm run replicate-tests-db`
```

## Tests

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
docker-compose exec inventaire ./node_modules/.bin/mocha --compilers coffee:coffee-script/register --timeout 20000 /opt/inventaire/path/to/test/file
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

## Troubleshooting

### Elasticsearch errors
- `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`: fix by running the command `sudo sysctl -w vm.max_map_count=262144` on your host machine

See also [Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/docker.html)

### Quieting CouchDB notice
CouchDB may warn constantly that `_users` database does not exist, [as documented](https://docs.couchdb.org/en/latest/setup/single-node.html), you can create de database with:

`curl -X PUT http://127.0.0.1:5984/_users`
