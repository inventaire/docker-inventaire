Run your own inventaire in a docker environment
Used only for testing and development purposes, so use in production at your own risk.

## Requirements

- [docker-compose](https://docs.docker.com/compose/gettingstarted/) up and ready
- git

## Install

```bash
git clone https://github.com/inventaire/inventaire-docker.git
```

got to `cd inventaire-docker`

clone the two repos inventaire needs to run :

 - `inventaire` core application server -> [setup](https://github.com/inventaire/inventaire#installation)
 - `entities-search-engine` for querying entities -> [go to repo](https://github.com/inventaire/entities-search-engine)

```bash
git clone https://github.com/inventaire/inventaire.git
git clone https://github.com/inventaire/entities-search-engine.git
```


Create empty folders for docker volumes to set themselves.
In accordance with docker-compose volumes, example: `mkdir data couch-test couch es`

Start the magic, build everything !

```bash
docker-compose build
```

Then download de Node dependencies, thanks to the magnificient `npm`:

```bash
docker-compose run --rm inventaire npm install
docker-compose run --rm entities-search-engine npm install
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

It's possible that elasticsearch import limit is below the entities-search-engige import rate

```bash
curl -XPOST http://localhost:9200/wikidata/_close
curl -XPUT http://localhost:9200/wikidata/_settings -d '{"index.mapping.total_fields.limit": 20000}'
curl -XPOST http://localhost:9200/wikidata/_open
```

Index all wd items with statement `wdt:P31 wd:Q5` aka all humans :

```bash
docker-compose exec entities-search-engine ./bin/dump_wikidata_subset P31:Q5 humans
```

[More info on importing some wikidata items](https://github.com/inventaire/inventaire-deploy/install_entities_search_engine)

More docs [wikidata filtered dump import](https://github.com/inventaire/entities-search-engine/blob/master/docs/wikidata_filtered_dump_import.mdFv)

## Enable inventaire items to be searchable

To index inventaire items created locally, enable updater in `inventaire/config/locale.js`:

```js
entitiesSearchEngine: {
  updateEnabled: true
}
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

`couchdb2elastic4sync` is a small libary in charge of maintaining ES indexes up to date with couchdb documents (only for `users` and `groups` since `entities` are handdled by `entities-search-engine`). If `couchdb2elastic4sync` does not find Elasticsearch search. Make sure configs files exists in `inventaire/scripts/couch2elastic4sync/configs`. They should be created during postinstall, but if the folder is empty, run the following scripts to create it :

```bash
docker-compose exec inventaire npm run couch2elastic4sync:init
docker-compose exec inventaire npm run couch2elastic4sync:load
```
