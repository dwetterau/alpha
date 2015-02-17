module.exports = (sequelize, DataTypes) ->
  Comment = sequelize.define "Comment",
    value:
      type: DataTypes.STRING
  , classMethods:
    associate: (models) ->
      Comment.belongsTo(models.User)
      Comment.belongsTo(models.Image)
      Comment.belongsTo(models.Album)
      Comment.belongsTo(Comment)
      Comment.hasMany(Comment)
  return Comment
