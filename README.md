Run your own inventaire in a docker environment
Used only for testing and development purposes, so use in production at your own risk.

## Requirements

- [docker-compose](https://docs.docker.com/compose/gettingstarted/) up and ready
- git

## Install

```bash
git clone https://github.com/inventaire/inventaire-docker.git
```

got to `cd docker-inventaire`

clone `inventaire` core application server -> [setup](https://github.com/inventaire/inventaire#installation)

```bash
git clone https://github.com/inventaire/inventaire.git
```


Create empty folders for docker volumes to set themselves.

In accordance with docker-compose volumes, example: `mkdir data couch-test couch es`.

Ensure the owner ID of those folders is 1000: `chown -R 1000:1000`.

Start the magic, build everything !

```bash
docker-compose build
```

Download Node dependencies:

```bash
docker-compose run --rm inventaire npm install
```

Configure inventaire so that it can connect to CouchDB:

```bash
echo "module.exports = {
  db: {
    username: 'couchdb',
    password: 'password'
  }
}
" > ./inventaire/config/local.js
```

You can optionnally install translation dependencies of[inventaire-i18n](https://github.com/inventaire/inventaire-i18n/) [need more details]

### Troubleshooting
#### elasticsearch errors
- `max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]`: fix by running the command `sudo sysctl -w vm.max_map_count=262144` on your host machine

See also [Elasticsearch with Docker](https://www.elastic.co/guide/en/elasticsearch/reference/7.9/docker.html)

## Usage

```bash
docker-compose up -d
```

## Create a user admin

A user admin is not that useful in development, it only allows you to merge/delete entities, see any user contributions, and a few more things. But if needed, start by signing up a user :

```bash
curl http://localhost:3006/api/auth?action=signup -d '{"username": "yourusername", "password": "yourpassword", "email":"some+email@example.org"}'
```

Grab the new user id

```bash
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

```bash
curl -XPOST http://localhost:9200/wikidata/_close
curl -H 'Content-Type:application/json' -H 'Accept: application/json' -XPUT http://localhost:9200/wikidata/_settings -d '{"index.mapping.total_fields.limit": 20000}'
curl -XPOST http://localhost:9200/wikidata/_open
```

## Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs (see Tests section)

```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```bash
`docker-compose exec inventaire npm run replicate-tests-db`
```

## Tests

Start services with test environnement with [multiple compose files](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files)

```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml up
```

Execute tests script

`docker-compose exec inventaire npm run test-api`

or execute directly the test command

`docker-compose exec inventaire ./node_modules/.bin/mocha --compilers coffee:coffee-script/register --timeout 20000 /opt/inventaire/path/to/test/file`

Tip : create a symbolic link on your machine between the inventaire folder and docker working directory on your machine at `/opt/`, in order to autocomplete path to test file to execute

`sudo ln ~/path/to/inventaire-docker/inventaire /opt -s`

Alternatively, as root in inventaire container:

`# mkdir /supervisor/path/to/inventaire`
`# ln -s /opt/ /supervisor/path/to/inventaire`

## Troubleshooting

### Elastic `users` and `groups` indexes are not up to date

`couchdb2elastic4sync` is a small libary in charge of maintaining ES indexes up to date with couchdb documents. If `couchdb2elastic4sync` does not find Elasticsearch search. Make sure configs files exists in `inventaire/scripts/couch2elastic4sync/configs`. They should be created during postinstall, but if the folder is empty, run the following scripts to create it :

```bash
docker-compose exec inventaire npm run couch2elastic4sync:init
docker-compose exec inventaire npm run couch2elastic4sync:load
```
