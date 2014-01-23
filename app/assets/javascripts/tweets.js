//= require _html-autoload
$(function() {
    var format_tweet = function() {
        $("time").text(new Date($("time").attr("datetime")).toLocaleString());
    };

    $.autopager({
        content: $(".tweets"),
        link: $("link[rel=next]"),
        onStart: function() {
            $(".loading").show();
        },
        onComplete: function() {
            $(".loading").hide();
            format_tweet();
        }
    });

    format_tweet();
});

