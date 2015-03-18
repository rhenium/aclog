Application.Views.tweets =
  _: ->
    formatTweet = (d) ->
      Application.Helpers.localize_time(d)
      Application.Helpers.rescue_profile_image(d)
    formatTweet $(".statuses")

    if $("link[rel=next]").length
      $.autopager
        content: $(".statuses")
        link: $("link[rel=next]")
        onStart: -> $(".loading").show()
        onReceived: (obj) -> formatTweet(obj)
        onComplete: -> $(".loading").hide()

      $(".statuses").on "click", ".expand-responses-button", ->
        id = $(this).data("id")
        type = $(this).data("type")
        Application.Helpers.call_api "tweets/responses", { id: id, type: type }, (json) ->
          obj = $(".status[data-id=\"" + id + "\"] .status-responses-" + type).html(json.html)
          Application.Helpers.rescue_profile_image obj
        return false
