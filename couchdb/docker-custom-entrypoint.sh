#!/bin/bash
/usr/local/bin/init_users_db.sh &
tini -- /docker-entrypoint.sh "$@"