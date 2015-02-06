Application.Parts.sidebar_user_stats = ->
  loading = $(".user-stats .loading").show()
  Application.Helpers.call_api "users/stats", { id: Application.Helpers.user_id() }, (json) ->
    if json.registered
      t = $("<ul />").addClass("records")
      $(".user-stats").append(t)
      addcol = (title, data, si) ->
        d = $("<span />").addClass("data").text(data)
        if si
          d.append($("<span />").text(si))
        line = $("<li />").append($("<span />").text(title)).append(d)
        t.append(line)
      l = [
        ["Received", json.reactions_count],
        ["Average", Math.round(json.reactions_count / json.tweets_count * 100) / 100],
        ["Joined", json.since_join, "d ago"]
      ]
      l.forEach (l) -> addcol(l[0], l[1], l[2])
    else
      $(".user-stats").append(
        $("<div />").addClass("alert").addClass("alert-aclog")
          .text("@" + Application.Helpers.user_screen_name() + " は aclog に登録していません"))
    loading.hide()
