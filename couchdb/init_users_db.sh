#!/bin/bash

while :; do {
  echo "[init_users_db.sh] Waiting for CouchDB to be online to initialize the _users database"
  curl http://localhost:5984 && {
    echo "[init_users_db.sh] CouchDB is online! Trying to initialize _users database"
    curl --user "$COUCHDB_USER:$COUCHDB_PASSWORD" -XPUT  http://localhost:5984/_users
    break
  } || {
    sleep 1
  }
}; done
