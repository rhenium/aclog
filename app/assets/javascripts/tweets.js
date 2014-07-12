Application.tweets = {
    _: function() {
        if ($("#statuses")) {
            var format_tweet = function(d) {
                $("time", d).each(
                    function() {
                        $(this).text(new Date($(this).attr("datetime"))
                                     .toLocaleString());
                    });
            };
            format_tweet($(".statuses"));

            if ($("link[rel=next]")) {
                $.autopager({
                    content: $(".statuses"),
                    link: $("link[rel=next]"),
                    onStart: function() {
                        $(".loading").show();
                    },
                    onReceived: function(obj) {
                        format_tweet(obj);
                    },
                    onComplete: function() {
                        $(".loading").hide();
                    }
                });
            }
        }

        $(".statuses").on("click", ".expand-responses-button", function() {
            var id = $(this).attr("data-id");
            var type = $(this).attr("data-type");
            $.getJSON("/i/" + id + "/" + type + ".json", function(json) {
                $(".status[data-id=\"" + id + "\"] .status-responses-" + type).html(json.html);
            });
        });
    }
};
