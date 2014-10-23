nconf = require('nconf')

readConfig = () ->
  nconf.argv()
    .env()
    .file { file: __dirname + '/../../../configs/config.json' }
  return nconf

module.exports = readConfig()
