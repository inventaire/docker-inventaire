Readme

To run inventaire in a docker-compose setup

## Install

Get [docker-compose](https://docs.docker.com/compose/gettingstarted/) on your machine

Clone this repo

```
git clone https://github.com/inventaire/inventaire-docker.git
```

got to `cd inventaire-docker`

clone the two repos inventaire needs to run :

 - `inventaire` -> [setup](https://github.com/inventaire/inventaire#installation)
 - `entities-search-engine`

```
git clone https://github.com/inventaire/inventaire.git
git clone https://github.com/inventaire/entities-search-engine.git
```

Copy docker utils files into inventaire folder if necessary

```
cp (or ln) utils/config/local.coffee inventaire/config/local.coffee
```

Start the magic

```
docker-compose up --build
```

Once containers have been build, you can simply `docker-compose up`

## Load wikidata into elasticsearch

start the containers `docker-compose up`

```
claim=P31:Q5
type=humans
docker-compose exec entities-search-engine ./bin/dump_wikidata_subset claim type
```

for more [info](https://github.com/inventaire/entities-search-engine/blob/master/docs/wikidata_filtered_dump_import.md)

## Fixtures

In case you would like to play with out-of-the-box data.

Run api tests to populate tests dbs:

```
docker-compose exec inventaire npm run test-api
```

- Replicate `*-tests` dbs documents into `*` dbs

```
docker-compose exec inventaire npm run replicate-tests-db
```
