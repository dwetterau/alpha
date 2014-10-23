module.exports = (sequelize, DataTypes) ->
  User = sequelize.define "User",
    username: DataTypes.STRING
    password: DataTypes.STRING
    salt: DataTypes.STRING
  , classMethods:
    associate: (models) ->
      User.hasMany(models.Image)

  return User
