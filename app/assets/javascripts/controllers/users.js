Views.users = {
  stats: function() {
    var drawgraph = function(target, data_raw, det) {
      var vm = new Vue({
        el: target,
        data: {
          users: data_raw.users,
          users_count: data_raw.users_count,
          reactions_count: data_raw.reactions_count,
          colors: ["#393b79", "#5254a3", "#6b6ecf", "#9c9ede", "#637939", "#8ca252", "#b5cf6b", "#cedb9c", "#8c6d31", "#bd9e39", "#e7ba52", "#e7cb94", "#843c39", "#ad494a", "#d6616b", "#e7969c", "#7b4173", "#a55194", "#ce6dbd", "#de9ed6"],
          loading: false,
          showTweets: false,
          statuses: [],
          lastUser: null
        },
        computed: {
          tweetsUrl: function() {
            var d = det(this.lastUser);
            return "/" + d[0] + "/favorited_by/" + d[1];
          },
          tweetsApi: function() {
            var d = det(this.lastUser);
            return "/i/api/tweets/user_favorited_by.json?screen_name=" + d[0] + "&source_screen_name=" + d[1];
          }
        },
        methods: {
          openTweets: function(user, e) {
            if (!this.showTweets || user === this.lastUser) {
              this.showTweets = !this.showTweets;
            }
            if (this.showTweets) {
              this.lastUser = user;
              vm = this;
              superagent
                .get(vm.tweetsApi)
                .query({ count: 3 })
                .accept("json")
                .end(function(err, res) {
                  var json = res.body;
                  vm.statuses = json.statuses;
                });
            }
          },
        },
      });
    };

    superagent
      .get("/i/api/users/favorited_by.json")
      .query({ screen_name: Helpers.user_screen_name() })
      .accept("json")
      .end(function(err, res) {
        var json = res.body;
        drawgraph("#favorited_by", res.body, function(user) { return [Helpers.user_screen_name(), user.screen_name]; });
      });
    superagent
      .get("/i/api/users/favorited_users.json")
      .query({ screen_name: Helpers.user_screen_name() })
      .accept("json")
      .end(function(err, res) {
        var json = res.body;
        drawgraph("#favorited_users", res.body, function(user) { return [user.screen_name, Helpers.user_screen_name()]; });
      });
  },
};