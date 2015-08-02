Views.apidocs = {
  endpoint: function() {
    var loading = $("#example_request_loading");
    if (loading) {
      var code = loading.parent();
      superagent
        .get($("#example_request_uri").text())
        .accept("json")
        .end(function(err, res) {
          if (res.ok) {
            return code.text(JSON.stringify(res.body, null, 2));
          } else {
            return code.text("failed to load example....");
          }
        });
    }
  }
};
