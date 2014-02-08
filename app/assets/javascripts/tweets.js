//= require _html-autoload
$(function() {
    var format_tweet = function() {
        $("time").each(
            function() {
                $(this).text(new Date($(this).attr("datetime"))
                             .toLocaleString())
            });
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

