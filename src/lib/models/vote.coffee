module.exports = (sequelize, DataTypes) ->
  Vote = sequelize.define "Vote",
    value:
      type: DataTypes.INTEGER
  , classMethods:
    associate: (models) ->
      Vote.belongsTo(models.User)
      Vote.belongsTo(models.Image)

  return Vote
