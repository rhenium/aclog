$ ->
  loading = false
  opts = null

  $.autopager = (_opts) ->
    defaults =
      content: $("#content")
      link: $("link[rel=next]")
      onStart: ->
      onReceived: (obj) ->
      onComplete: ->
    opts = $.extend({}, defaults, _opts)

    $(window).scroll ->
      if (opts.content.offset().top + opts.content.height()) - ($(document).scrollTop() + $(window).height()) < 100
        if loading || !opts.link || !opts.link.attr("href")
          return

        opts.onStart()
        loading = true
        $.getJSON opts.link.attr("href"), (json, status) ->
          obj = $(json.html)
          opts.onReceived(obj)
          opts.content.append(obj)
          opts.link.attr("href", json.next_url)
          loading = false
          opts.onComplete()
