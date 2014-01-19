(function($) {
    var loading = false;
    var opts = null;

    $.autopager = function(_opts) {
        var defaults = {
            content: $("#content"),
            link: $("link[rel=next]"),
            onStart: function() { },
            onComplete: function() { }
        };
        opts = $.extend({}, defaults, _opts);

        $(window).scroll(function() {
            if ((opts.content.offset().top + opts.content.height()) < ($(document).scrollTop() + $(window).height())) {
                if (loading || !opts.link || !opts.link.attr("href")) return;

                opts.onStart();
                loading = true;
                $.getJSON(opts.link.attr("href"), function(json, status) {
                    opts.content.append(json.html);
                    opts.link.attr("href", json.next_url);
                    loading = false;
                    opts.onComplete();
                });
            }
        });
    }
})($);

