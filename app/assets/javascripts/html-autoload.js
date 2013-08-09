(function($) {
    var window = this,
        options = {},
        content,
        nextUrl,
        page = 1,
        loading = false;

    $.autopager = function(_options) {
        var autopager = this.autopager;

        var defaults = {
            content: "#content",
            nextLink: "a[rel=next]",
            onStart: function() {},
            onComplete: function() {}
        };

        options = $.extend({}, defaults, _options);
        content = $(options.content);
        nextUrl = $(options.nextLink).attr("href");
        
        $(window).scroll(function() {
            if (content.offset().top + content.height() < $(document).scrollTop() + $(window).height()) {
                $.autopager.loadNext();
            }
        });

        return this;
    };

    $.extend($.autopager, {
        loadNext: function() {
            if (loading || !nextUrl) {
                return;
            }

            loading = true;
            options.onStart();
            $.getJSON(nextUrl, insertContent);
            return this;
        }
    });

    function insertContent(json) {
        var nextPage = $(json.html);

        page = page + 1;
        nextUrl = json.next;
        $(options.nextLink).attr("href", nextUrl);
        content.append(nextPage);
        options.onComplete();
        loading = false;
    }
})(jQuery);
