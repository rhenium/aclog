//= require _html-autoload
$(function() {
    $(".pagination").hide();
    $.autopager({
        content: $(".tweets"),
        link: $("link[rel=next]"),
        onStart: function() {
            // $(".loading").show();
        },
        onComplete: function() {
            // $(".loading").hide();
        }
    });
});

