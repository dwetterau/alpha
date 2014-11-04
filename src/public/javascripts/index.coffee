# Register right and left button handlers
if $('#next_link').length and $('#previous_link').length
  $('body').keydown (e) ->
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
if $('.up_link').length and $('.down_link').length
  request = (url) ->
    $.get url, (response) ->
      if not response.score? and not response.msg?
        window.location = '/user/login'
      $('#' + response.id + '-score').text(response.score)

  $('.up_link').click (e) ->
    request e.target.href
    e.preventDefault()
    return false

  $('.down_link').click (e) ->
    request e.target.href
    e.preventDefault()
    return false