Views.tweets = {
  _: function() {
    var vm = new Vue({
      el: ".statuses",
      data: {
        statuses: [],
        loading: false,
        next: null,
        prev: null,
      },
      methods: {
        clear: function() {
          this.statuses = [];
        },
        loadNext: function(nextUrl, queryString) {
          vm = this;
          if (vm.loading || (!nextUrl && !vm.next)) { return; }
          vm.loading = true;
          superagent
            .get(nextUrl || vm.next)
            .query(queryString || {})
            .accept("json")
            .end(function(err, res) {
              var json = res.body;
              vm.statuses = vm.statuses.concat(json.statuses);
              vm.next = json.next;
              vm.loading = false;
            });
        },
      },
    });

    var content = $(".statuses");
    $(window).scroll(function() {
      if ((content.offset().top + content.height()) - ($(document).scrollTop() + $(window).height()) < 100) {
        vm.loadNext();
      }
    });

    if (!Views.tweets[Helpers.action()]) {
      var query = Helpers.request_params();
      var url = "/i/api/" + Helpers.controller() + "/" + Helpers.action() + ".json";
      vm.loadNext(url, query);
    }
  },
  show: function() {
    var _query = Helpers.request_params();
    var vm = new Vue({
      el: ".statuses",
      data: {
        statuses: [],
        loading: false
      },
      methods: {
        reload: function(e) {
          if (e) { e.preventDefault(); }
          if (this.loading) { return; }
          vm = this;
          vm.loading = true;
          superagent
            .post("/i/api/tweets/update.json")
            .query(_query)
            .send({ authenticity_token: Helpers.authenticity_token() })
            .accept("json")
            .end(function(err, res) {
              var json = res.body;
              vm.statuses = json.statuses;
              vm.loading = false;
            });
        },
        load: function() {
          if (this.loading) { return; }
          vm = this;
          vm.loading = true;
          superagent
            .get("/i/api/tweets/show.json")
            .query(_query)
            .accept("json")
            .end(function(err, res) {
              var json = res.body;
              console.log(json);
              vm.statuses = json.statuses;
              vm.loading = false;
            });
        },
      },
    });
    vm.load();
  },
};
