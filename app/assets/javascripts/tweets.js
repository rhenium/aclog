Application.tweets = {
    _: function() {
        var formatTweet = function(d) {
            $("time", d).each(function() {
                $(this).text(new Date($(this).attr("datetime"))
                                .toLocaleString());
            });
        };
        formatTweet($(".statuses"));

        if ($("link[rel=next]") !== null) {
            $.autopager({
                content: $(".statuses"),
                link: $("link[rel=next]"),
                onStart: function() {
                    $(".loading").show();
                },
                onReceived: function(obj) {
                    formatTweet(obj);
                },
                onComplete: function() {
                    $(".loading").hide();
                }
            });
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
