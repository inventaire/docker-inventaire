#!/usr/bin/env bash

set -eu

cd /opt/inventaire

# Overwrite the local-${NODE_ENV} config with environment variables every time the container is restarted
cat > "./config/local-${NODE_ENV}.cjs" << EOF
module.exports = {
  hostname: 'inventaire',
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
  },
  mailer: {
    disabled: false,
    nodemailer: {
      host: '${MAILER_SMTP_HOST}',
      port: ${MAILER_SMTP_PORT},
      auth: {
        user: '${MAILER_SMTP_USERNAME}',
        pass: '${MAILER_SMTP_PASSWORD}'
      },
    },
  },

}
EOF

./scripts/typescript/start_built_server.sh
