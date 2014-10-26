fs = require 'fs-extra'
im = require 'imagemagick'
uuid = require 'node-uuid'

models = require '../models'

get_upload = (req, res) ->
  res.render 'upload',
    username: req.user.username

post_upload = (req, res) ->
  error_exit = (err) ->
    req.flash 'errors', err
    res.redirect '/image/upload'

  id = uuid.v4()
  original_path = './image/original/' + id
  optimized_path = './image/optimized/' + id + ".jpg"
  thumbnail_path = './image/thumbnail/' + id + ".jpg"

  console.log {original_path}
  req.pipe req.busboy
  req.busboy.on 'file', (fieldname, file, filename) ->
    console.log {fieldname, file, filename}
    if not filename
      return error_exit {msg: "No filename."}

    file_stream = fs.createWriteStream original_path
    file.pipe file_stream
    file_stream.on 'close', () ->
      # Now we need to convert the image to jpg and resize for thumbnails
      im.convert [original_path, '-resize', '640', optimized_path], (err, stdout) ->
        if err
          return error_exit err
        # Now make a thumbnail of it too
        im.resize {
          srcPath: optimized_path
          dstPath: thumbnail_path
          width: 200
          height: 200
        }, (err, stdout, stderr) ->
          if err
            return error_exit err
          console.log "All done!"
          req.flash 'success', {msg: 'Upload Successful!'}
          res.redirect '/image/upload'

module.exports = {
  get_upload,
  post_upload
}
