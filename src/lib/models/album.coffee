module.exports = (sequelize, DataTypes) ->
  Album = sequelize.define "Album",
    title:
      type: DataTypes.STRING
      validate: {notEmpty: true}
    description:
      type: DataTypes.STRING(64000)
  , classMethods:
    associate: (models) ->
      Album.belongsTo(models.User)
      Album.hasMany(models.Image)
      Album.hasMany(models.Comment)
  return Album
