module.exports = (sequelize, DataTypes) ->
  Image = sequelize.define "Image",
    title: DataTypes.STRING
    description: DataTypes.STRING
    image_id: DataTypes.STRING
  , classMethods:
    associate: (models) ->
      Image.belongsTo(models.User)

  return Image
