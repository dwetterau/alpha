models = require '../models'
ranking = require '../ranking'
constants = require '../common/constants'

get_index_view = (offset, req, res) ->

  to_request = constants.images_per_page
  # Request one more than we want to see if there are any on the next page.
  ranking.get_best to_request + 1, offset, (err, reply) ->
    id_list = []
    scores = {}
    id_to_index = {}

    pagination = {
      previous_enabled: 'disabled'
      next_enabled: 'disabled'
      next_link: '#'
      previous_link: '#'
    }

    if offset > 0
      pagination.previous_enabled = undefined
      pagination.previous_link = '/page/' + (offset / to_request)

    for value, index in reply
      if index >= 32
        pagination.next_enabled = undefined
        pagination.next_link = '/page/' + (offset / to_request + 2)
        break
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
        title: 'Home',
        pagination
      }

get_index = (req, res) ->
  return get_index_view 0, req, res

get_index_page = (req, res) ->
  page_num = req.params.page_num
  offset = (page_num - 1) * constants.images_per_page
  return get_index_view offset, req, res

module.exports = {
  get_index
  get_index_page
}