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
if $('.vote-button').length
  $("body").on "click", ".vote-button", () ->
    url = $(this).attr('data-href')
    $.get url, (response) =>
      if not response.score? and not response.msg?
        window.location = '/user/login'
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
