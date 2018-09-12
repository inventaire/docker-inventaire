Run your own inventaire in a docker environment

## Requirements

- [docker-compose](https://docs.docker.com/compose/gettingstarted/) up and ready
- git

## Install

```
git clone https://github.com/inventaire/inventaire-docker.git
```

got to `cd inventaire-docker`

clone the two repos inventaire needs to run :

 - `inventaire` core application server -> [setup](https://github.com/inventaire/inventaire#installation)
 - `entities-search-engine` for querying entities -> [go to repo](https://github.com/inventaire/entities-search-engine)

```
git clone https://github.com/inventaire/inventaire.git
git clone https://github.com/inventaire/entities-search-engine.git
```

Start the magic, build everything at once !

```
docker-compose up --build
```

## Useful commands

`docker-compose up` : start containers if already built

`docker-compose down` : kill active containers

`docker rm $(docker ps -a -q)` : delete stopped containers

`docker rmi $(docker images -q -f dangling=true)` : delete untagged images

Check out [official doc](https://docs.docker.com/compose/)

## Load wikidata into elasticsearch

Make sure ES import limit is above entities-search-engige import rate, by raising the limit

```
docker-compose exec entities-search-engine curl -XPUT http://elasticsearch:9200/wikidata/_settings -d '{"index.mapping.total_fields.limit": 20000}'
```

start the containers `docker-compose up`

```
claim=P31:Q5
type=humans
docker-compose exec entities-search-engine ./bin/dump_wikidata_subset $claim $type
```

for more [info](https://github.com/inventaire/entities-search-engine/blob/master/docs/wikidata_filtered_dump_import.md)

## Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs (see Tests section)
```
`docker-compose -f docker-compose-test.yml exec inventaire npm run test-api`
```

- Replicate `*-tests` dbs documents into `*` dbs

```
`docker-compose exec inventaire npm run replicate-tests-db`
```

## Test environement

Start docker-compose-test `docker-compose -f docker-compose-test.yml up`

Execute tests script

`docker-compose exec inventaire npm run test-api`

or execute directly the test command

`docker-compose exec inventaire ./node_modules/.bin/mocha --compilers coffee:coffee-script/register --timeout 20000`
