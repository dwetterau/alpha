async = require 'async'

# Register right and left button handlers
if $('#next_link').length and $('#previous_link').length
  $('body').keydown (e) ->
    # Don't go to the next page if we are typing something
    if $('.comment-input').is(':focus')
      return

    if e.keyCode == 37
      $('#previous_link')[0].click()
    else if e.keyCode == 39
      $('#next_link')[0].click()
    else
      return
    e.preventDefault()
    return false

# Disable upload button on click
if $('#upload_image_form').length
  $('#upload_image_form').submit () ->
    $('#upload_button').attr('disabled', 'disabled')


# Upvote / Downvote AJAX
if $('.vote-button').length
  $("body").on "click", ".vote-button", () ->
    url = $(this).attr('data-href')
    $.get url, (response) =>
      if not response.score? and not response.msg?
        window.location = '/user/login?r=' + encodeURIComponent(window.location.pathname)
      score_element = $('#' + response.id + '-score')

      # Determine if we un-voted
      delta = if url.substring(url.length - 2) == 'up' then 1 else -1
      original = score_element.text()
      # Clear active from all parent's elements
      for child in $(this).parent().children()
        $(child).removeClass('active')
        $(child).blur();
      if delta + (response.score - original) != 0
        $(this).addClass('active')

      score_element.text(response.score)
    return true

# Load first level image comments
if $('#comment-div').length
  div = $('#comment-div')
  url = div.attr('data-href')
  $.get url, (response) ->
    div.html(response)

# Add another add image form
$('#add-another-image').click () ->
  id = $(this).parent().children().size() - 3

  newForm = $("<div>")
  newForm.addClass("form-group")

  newLabel = $('<label class="col-sm-3 control-label" for="image' + id + '">
    Image #' + id + '</label>')
  newUpload = $('<div class="col-sm-3"><input class="form-control"
    type="file" name="image" id="image' + id + '" /></div>')
  newDescription = $('<div class="col-sm-4"><input class="form-control" type="text"
    name="image' + id + '-desc" id="image' + id + '-desc"
    placeholder="Image description..." /></div>')
  newForm.append(newLabel).append(newUpload).append(newDescription)

  $(this).before(newForm)

$('#album-save-form').submit (e) ->
  # Disable the button while uploading
  $('#album-save-button').attr('disabled', 'disabled')

  # Upload all of the images, if any fail, stop
  numImages = $(this).children().size() - 4
  allImages = []

  saveImage = (id, callback) ->
    # Copy all the values to the hidden form
    # File inputs are really sketchy
    image = $('#image' + id)
    clone = image.clone()
    image.after(clone).appendTo('#upload_image_form')

    $('#description').val $('#image' + id + '-desc').val()

    $('#upload_image_form').unbind('submit').submit (e) ->
      $.ajax({
        url: '/api/image/upload'
        type: 'POST'
        data: new FormData this
        processData: false
        contentType: false
      }).done (data) ->
        # Clean up the form
        $('#upload_image_form input[type=file]').remove()
        console.log data
        if data.status = 'ok'
          allImages.push data.image
          callback()
        else
          # Just ignore the bad photo upload :(
          # callback(data.err)
      e.preventDefault()
      e.stopPropagation()
    $('#upload_image_form').submit()

  async.eachSeries [1..numImages], saveImage, (err) ->
    if err
      return console.log err

    $.ajax({
      url: '/album/create'
      type: 'POST'
      data: {
        title: $('#album-title').val()
        description: $('#album-description').val()
        images: allImages
      }
    }).done (data) ->
      window.location = data.redirect

    console.log allImages

  e.preventDefault()
  e.stopPropagation()


$(".alert").delay(3000).fadeOut(2000)
