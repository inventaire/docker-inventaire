module.exports =
  host: '0.0.0.0'
  elasticsearch:
    host: 'elasticsearch'
    port: '9200'
  db:
    protocol: 'http'
    # host defined in docker-compose couchdb image name
    host: 'couch'
    port: '5984'
    username: 'couchdb'
    password: 'password'
    debug: true
  runJobsInQueue:
    'wd:popularity': false
  entitiesSearchEngine:
    updateEnabled: false
    localPath: '/opt/entities-search-engine'
    delay: 3000
