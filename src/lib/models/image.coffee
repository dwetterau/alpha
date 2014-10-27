module.exports = (sequelize, DataTypes) ->
  Image = sequelize.define "Image",
    title:
      type: DataTypes.STRING
      validate: {notEmpty: true}
    description:
      type: DataTypes.STRING
      validate: {notEmpty: true}
    image_id:
      type: DataTypes.STRING
      validate:
        notEmpty: true
      unique: true
  , classMethods:
    associate: (models) ->
      Image.belongsTo(models.User)

  return Image
