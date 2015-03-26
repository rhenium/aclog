Vue.config.prefix = "data-v-"
Vue.filter "toLocaleString", (string) ->
  new Date(string).toLocaleString()

if window.Views is undefined
  window.Views = {}
  window.Helpers = {}
  window.Parts = {}
