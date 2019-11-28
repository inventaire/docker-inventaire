Run your own inventaire in a docker environment

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
echo "module.exports =
  db:
    username: 'couchdb'
    password: 'password'
" > ./inventaire/config/local.coffee
```
This command run also the postinstall script which install the client

Install also the translation dependencies of
[inventaire-i18n](https://github.com/inventaire/inventaire-i18n/) [need more details]

Finally, start the build with

```
docker-compose up -d
```

## Useful commands

`docker-compose up` : start containers if already built

`docker-compose down` : kill active containers

`docker rm $(docker ps -a -q)` : delete stopped containers

`docker rmi $(docker images -q -f dangling=true)` : delete untagged images

Check out [official doc](https://docs.docker.com/compose/)

## Load wikidata into elasticsearch

Make sure ES import limit is above entities-search-engige import rate, by [closing the index](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html) first, raising the limit & reopen the index

```
curl -XPOST http://localhost:9200/wikidata/_close
curl -XPUT http://localhost:9200/wikidata/_settings -d '{"index.mapping.total_fields.limit": 20000}'
curl -XPOST http://localhost:9200/wikidata/_open
```

Make sure to have containers running then :

```
docker-compose exec entities-search-engine ./bin/dump_wikidata_subset P31:Q5 humans
```

[More info on importing some wikidata items](https://github.com/inventaire/inventaire-deploy/install_entities_search_engine)

More docs [wikidata filtered dump import](https://github.com/inventaire/entities-search-engine/blob/master/docs/wikidata_filtered_dump_import.mdFv)

## Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs (see Tests section)
```
docker-compose -f docker-compose.yml -f docker-compose.test.yml exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```
`docker-compose exec inventaire npm run replicate-tests-db`
```

## Tests

Start services with test environnement with [multiple compose files](https://docs.docker.com/compose/extends/#understanding-multiple-compose-files)

```
docker-compose -f docker-compose.yml -f docker-compose.test.yml up
```

Execute tests script

`docker-compose exec inventaire npm run test-api`

or execute directly the test command

`docker-compose exec inventaire ./node_modules/.bin/mocha --compilers coffee:coffee-script/register --timeout 20000 /opt/inventaire/path/to/test/file`

Tip : create a symbolic link on your machine between the inventaire folder and docker working directory on your machine at `/opt/`, in order to autocomplete path to test file to execute

`sudo ln ~/path/to/inventaire-docker/inventaire /opt -s`
