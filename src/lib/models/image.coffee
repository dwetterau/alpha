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
    score_base:
      type: DataTypes.FLOAT
    extension:
      type: DataTypes.STRING
      defaultValue: '.jpg'
  , classMethods:
    associate: (models) ->
      Image.belongsTo(models.User)
      Image.hasMany(models.Vote)
      Image.hasMany(models.Comment)
  return Image
