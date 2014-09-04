(function($) {
    var loading = false;
    var opts = null;

    $.autopager = function(_opts) {
        var defaults = {
            content: $("#content"),
            link: $("link[rel=next]"),
            onStart: function() { },
            onReceived: function(obj) { },
            onComplete: function() { }
        };
        opts = $.extend({}, defaults, _opts);

        $(window).scroll(function() {
            if ((opts.content.offset().top + opts.content.height()) - ($(document).scrollTop() + $(window).height()) < 100) {
                if (loading || !opts.link || !opts.link.attr("href")) return;

                opts.onStart();
                loading = true;
                $.getJSON(opts.link.attr("href"), function(json, status) {
                    var obj = $(json.html)
                    opts.onReceived(obj);
                    opts.content.append(obj);
                    opts.link.attr("href", json.next_url);
                    loading = false;
                    opts.onComplete();
                });
            }
        });
    }
})($);
