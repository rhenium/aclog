Application.apidocs = {
    endpoint: function() {
        var loading = $("#example_request_loading");
        if (loading) {
            var code = loading.parent();
            $.ajax($("#example_request_uri").text()).done(function(data) {
                code.text(JSON.stringify(data, null, 2));
            }).fail(function() {
                code.text("failed to load example....");
            });
        }
    }
};

