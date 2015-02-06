#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap-sprockets
#= require _widgets
#= require _define_application
#= require_tree .

$ ->
  controller = $("body").data("controller")
  action = $("body").data("action")
  parts = ($("body").data("parts") || "").split(" ")

  ac = Application.Views[controller]
  if ac
    ac["_"]?()
    ac["action"]?()

  parts.forEach (par) ->
    pa = Application.Parts[par]
    pa?()
