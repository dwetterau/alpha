fs = require "fs"
path = require "path"
Sequelize = require "sequelize"
env = process.env.NODE_ENV || "local"
{config} = require('../common')

sequelize = new Sequelize(
  config.get('database'),
  config.get('db_username'),
  config.get('db_password'),
  config.get('db_config')
)

db = {}

files = (file for file in fs.readdirSync(__dirname) when (
  file.indexOf(".") != 0 and file != "index.js" and file.indexOf(".js") != -1))

for file in files
  model = sequelize["import"] path.join(__dirname, file)
  db[model.name] = model

for model_name, model of db
  if "associate" of model
    db[model_name].associate db

db.sequelize = sequelize
db.Sequelize = Sequelize
module.exports = db
