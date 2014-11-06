fs = require 'fs-extra'
im = require 'imagemagick'
uuid = require 'node-uuid'

models = require '../models'
ranking = require '../ranking'

render_and_return_comments = (comment_list, req, res, title) ->
  if comment_list.length == 0
    return res.render 'partials/comments', {}
  comments = []
  for comment in comment_list
    comments.push {
      value: comment.value
      user_id: comment.UserId
    }
  user_ids = (comment.user_id for comment in comments)
  models.User.findAll({where: {id: user_ids}}).success (users) ->
    user_map = {}
    for user in users
      user_map[user.id] = user.username
    for comment in comments
      comment.username = user_map[comment.user_id]
    res.render 'partials/comments', {comments, title}
  .failure () ->
    res.render 'partials/comments', {comments}

exports.get_comments_for_image = (req, res) ->
  image_id = req.params.image_id
  models.Image.find({
    where: {image_id},
    include: [models.Comment]
  }).success (image) ->
    render_and_return_comments image.Comments, req, res, "Comments:"
  .failure () ->
    render_and_return_comments [], req, res

exports.get_child_comments = (req, res) ->
  # TODO: Get all comments that are a child of the given comment

exports.post_comment = (req, res) ->
  req.assert('comment', 'Comments must be at least a character long.').notEmpty()
  req.assert('image_id', 'Image id must be valid').notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash 'errors', errors
    return res.redirect '/user/create'

  error = () ->
    req.flash 'errors', {msg: 'Failed to post comment.'}
    res.redirect '/image/' + image_id

  image_id = req.body.image_id
  models.Image.find({
    where: {image_id}
  }).success (image) ->
    # Yay we have the image to set the new comment as.
    new_comment = models.Comment.build(
      value: req.body.comment
      ImageId: image.id
      UserId: req.user.id
    )
    new_comment.save().success () ->
      req.flash 'success', {msg: 'Comment posted!'}
      res.redirect '/image/' + image_id
  .failure error

