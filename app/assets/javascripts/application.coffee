### TODO
#= require jquery
#= require jquery_ujs
#= require bootstrap/dropdown
#= require _widgets
###
#= require twitter-text-1.11.0
#= require superagent-1.1.0
#= require vue-0.11.5
#= require _init
#= require _helpers
#= require_tree .

$ ->
  ac = Views[Helpers.controller()]
  if ac
    ac["_"]?()
    ac[Helpers.action()]?()

  Helpers.parts().forEach (par) ->
    (Parts[par])?()
