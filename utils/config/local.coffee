module.exports =
  env: 'production'
  host: '0.0.0.0'
  db:
    protocol: 'http'
    # host defined in docker-compose couchdb image name
    host: 'couch'
    port: '5984'
    username: 'couchdb'
    password: 'password'
    debug: true
