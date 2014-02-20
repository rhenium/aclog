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
    }
};

