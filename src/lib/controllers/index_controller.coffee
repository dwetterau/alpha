models = require '../models'
ranking = require '../ranking'

get_index = (req, res) ->
  to_request = 5

  ranking.get_best to_request, 0, (err, reply) ->
    console.log reply
    id_list = []
    scores = {}
    id_to_index = {}
    for value, index in reply
      if index % 2 == 0
        id_to_index[value] = id_list.length
        id_list.push(value)
      else
        scores[reply[index - 1]] = -value

    sorted_images = (0 for _ in [0...Math.min(to_request, id_list.length)])
    models.Image.findAll({where: {id: id_list}}).success (images) ->
      for image in images
        sorted_images[id_to_index['' + image.id]] = image
      res.render 'index', {
        images: sorted_images,
        scores,
        user: req.user,
        title: 'Home'
      }


module.exports = {
  get_index
}