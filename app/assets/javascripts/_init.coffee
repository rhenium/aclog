Vue.config.prefix = "data-v-"
Vue.filter "toLocaleString", (string) ->
  new Date(string).toLocaleString()
Vue.filter "removeInvalidCharacters", (str) ->
  # JavaScript is kuso: http://www.w3.org/TR/xml/#charsets
  str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F]/gm, "")

if window.Views is undefined
  window.Views = {}
  window.Helpers = {}
  window.Parts = {}
