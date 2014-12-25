models = require '../lib/models'
models.sequelize
.drop()
.complete (err) ->
  if err?
    console.log "An error occurred while creating the table", err
  else
    console.log "dropped tables."