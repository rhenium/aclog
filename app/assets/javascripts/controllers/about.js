Views.about = {
  index: function() {
    Array.prototype.forEach.call(document.querySelectorAll(".tweet-button a"), function(node) {
      node.onclick = function(e) {
        e.preventDefault();
        Helpers.openTwitterIntent(node.getAttribute("href"));
      };
    });
  },
  status: function() {
    var vm = new Vue({
      el: "#status",
      data: {
        nodes: {},
        active_nodes: [],
        inactive_nodes: [],
        loading: false,
        error: null,
      },
      methods: {
        uptime: function (i) {
          var diff = Math.floor(Date.now() / 1000) - this.nodes[i].activated_at;
          if (diff < 5 * 60) {
            return diff.toString() + " seconds";
          } else if (diff < 5 * 60 * 60) {
            return Math.floor(diff / 60).toString() + " minutes";
          } else if (diff < 48 * 60 * 60) {
            return Math.floor(diff / 60 / 60).toString() + " hours";
          } else {
            return Math.floor(diff / 60 / 60 / 24).toString() + " days";
          }
        },
        reload: function (e) {
          if (e) { e.preventDefault(); }
          if (vm.loading) { return; }
          vm.loading = true;
          superagent
            .get("/i/status.json")
            .accept("json")
            .end(function (err, res) {
              var json = res.body;
              vm.loading = false;
              if (json.error) {
                vm.error = json.error;
              } else {
                vm.error = null;
                vm.nodes = json.nodes;
                vm.active_nodes = json.active_nodes;
                vm.inactive_nodes = json.inactive_nodes;
              }
            });
        },
      },
    });
    vm.reload();
  },
};
