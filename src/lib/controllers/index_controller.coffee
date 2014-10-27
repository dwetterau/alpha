models = require '../models'
ranking = require '../ranking'

get_index = (req, res) ->
  ranking.get_best 5, 0, (err, reply) ->
    id_list = []
    scores = {}
    for value, index in reply
      if index % 2 == 0
        id_list.push(value)
      else
        scores[Math.floor(index / 2)] = value

    models.Image.findAll({where: {id: id_list}}).success (images) ->
      res.render 'index', {
        images,
        scores,
        user: req.user,
        title: 'Home'
      }


module.exports = {
  get_index
}