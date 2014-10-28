models = require '../models'
ranking = require '../ranking'
constants = require '../common/constants'

get_index = (req, res) ->
  to_request = 16

  ranking.get_best to_request, 0, (err, reply) ->
    id_list = []
    scores = {}
    id_to_index = {}
    for value, index in reply
      if index % 2 == 0
        id_to_index[value] = id_list.length
        id_list.push(value)
      else
        scores[reply[index - 1]] = parseFloat(value)

    sorted_images = (0 for _ in [0...Math.min(to_request, id_list.length)])
    models.Image.findAll({where: {id: id_list}}).success (images) ->
      for image in images
        sorted_images[id_to_index['' + image.id]] = image

        this_score = ranking.get_pretty_score scores[image.id], image.score_base
        scores[image.id] = this_score

      all_images = []
      current_row = []
      for image, index in sorted_images
        if index % 4 == 0 and current_row.length
          all_images.push current_row
          current_row = []
        current_row.push image

      if current_row.length
        all_images.push current_row

      res.render 'index', {
        images: all_images,
        scores,
        user: req.user,
        title: 'Home'
      }


module.exports = {
  get_index
}