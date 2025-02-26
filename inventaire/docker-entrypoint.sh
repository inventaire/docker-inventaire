#!/usr/bin/env bash

set -eu

# Overwrite the local config with environment variables every time the container is restarted
cat > ./config/local.cjs << EOF
module.exports = {
  port: '${INVENTAIRE_PORT}',
  publicHostname: '${PUBLIC_HOSTNAME}',
  instanceName: '${INSTANCE_NAME}',
  orgName: '${ORG_NAME}',
  orgUrl: '${ORG_URL}',
  contactAddress: '${CONTACT_ADDRESS}',

  db: {
    username: '${COUCHDB_USER}',
    password: '${COUCHDB_PASSWORD}',
    hostname: 'couchdb',
  },
  elasticsearch: {
    origin: 'http://elasticsearch:9200',
  }
}
EOF

./scripts/typescript/start_built_server.sh
