Parts.sidebar_user_stats = ->
  vm = new Vue
    el: ".user-stats"
    data:
      stats: null
      screen_name: Helpers.user_screen_name()
      loading: true
    computed:
      average: ->
        Math.round(this.stats.reactions_count / this.stats.tweets_count * 100) / 100

  superagent
    .get "/" + Helpers.user_screen_name() + "/stats"
    .accept "json"
    .end (err, res) ->
      vm.stats = res.body
      vm.loading = false
