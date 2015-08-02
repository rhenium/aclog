window.Shared.sidebar_user_stats = function() {
  var vm = new Vue({
    el: ".user-stats",
    data: {
      stats: null,
      screen_name: Helpers.user_screen_name(),
      loading: true
    },
    computed: {
      average: function() {
        return Math.round(this.stats.reactions_count / this.stats.tweets_count * 100) / 100;
      }
    }
  });
  superagent
    .get("/i/api/users/stats_compact.json")
    .query({ screen_name: Helpers.user_screen_name() })
    .accept("json")
    .end(function(err, res) {
      vm.stats = res.body;
      vm.loading = false;
    });
};
