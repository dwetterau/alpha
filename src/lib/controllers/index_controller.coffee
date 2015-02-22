{Album, Image} = require '../models'
ranking = require '../ranking'
constants = require '../common/constants'

get_index_view = (offset, req, res) ->

  to_request = constants.images_per_page
  # Request one more than we want to see if there are any on the next page.
  ranking.get_best to_request + 1, offset, (err, reply) ->
    id_list = []
    imageIdList = []
    albumIdList = []
    imageScores = {}
    albumScores = {}
    id_to_index = {}
    imageVotes = {}
    albumVotes = {}

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
        lastId = reply[index - 1]
        v = parseFloat(value)
        if lastId.indexOf(constants.album_prefix) == 0
          albumId = lastId.substring constants.album_prefix.length
          albumScores[albumId] = v
          albumIdList.push albumId
        else
          imageScores[lastId] = v
          imageIdList.push lastId

    sorted_content = (0 for _ in [0...Math.min(to_request, id_list.length)])
    images = []
    Image.findAll({where: {id: imageIdList}}).then (returnedImages) ->
      images = returnedImages
      return Album.findAll({where: {id: albumIdList}, include: [Image]})
    .then (albums) ->
      for image in images
        sorted_content[id_to_index['' + image.id]] = {isImage: true, image}

        this_score = ranking.get_pretty_score imageScores[image.id], image.score_base
        imageScores[image.id] = this_score
        imageVotes[image.id] = 0

      for album in albums
        thisAlbumId = constants.album_prefix + album.id
        sorted_content[id_to_index[thisAlbumId]] = {isImage: false, album}
        thisScore = ranking.get_pretty_score albumScores[album.id], album.scoreBase
        albumScores[album.id] = thisScore
        albumVotes[album.id] = 0

      allContent = []
      current_row = []
      for content, index in sorted_content
        if index % 4 == 0 and current_row.length
          allContent.push current_row
          current_row = []
        current_row.push content

      if current_row.length
        allContent.push current_row

      render_dict = {
        content: allContent
        imageScores
        albumScores
        user: req.user
        title: 'Home'
        pagination
        imageVotes
        albumVotes
      }
      # Get our votes and make them pretty
      if req.user
        req.user.getVotes().success (user_votes) ->
          for vote in user_votes
            if vote.ImageId?
              imageVotes[vote.ImageId] = vote.value
            else if vote.AlbumId?
              albumVotes[vote.AlbumId] = vote.value

          render_dict.imageVotes = imageVotes
          render_dict.albumVotes = albumVotes
          res.render 'index', render_dict
      else
        console.log render_dict
        res.render 'index', render_dict

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