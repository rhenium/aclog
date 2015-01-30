$ ->
  $("#user-jump-dropdown .dropdown-toggle").click () ->
    setTimeout (-> $("#user-jump-dropdown input").focus()), 0

  previousText = ""
  $("#user-jump-dropdown input").on "keyup", () ->
    if $(this).val() isnt previousText
      previousText = $(this).val()
      $("#user-jump-dropdown .user-jump-suggestion").remove()

      if previousText.length > 0
        Application.Helpers.call_api "users/suggest_screen_name", { head: previousText }, (json) ->
          menu = $("#user-jump-dropdown .dropdown-menu")
          json.forEach (s) ->
            img = $("<img />").addClass("twitter-icon").attr("src", s.profile_image_url).attr("alt", "@" + s.screen_name)

            menu.append($("<li />").addClass("user-jump-suggestion")
                .append($("<a />").attr("href", "/" + s.screen_name).attr("title", s.name + " (@" + s.screen_name + ")")
                    .append(img)
                    .append($("<span />").text("@" + s.screen_name))))
          Application.Helpers.rescue_profile_image(menu)
  $("#user-jump-dropdown form").on "submit", () ->
      window.location = "/" + $("input", this).val()
      return false
