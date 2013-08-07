(function($) {
    var window = this,
        options = {},
        content,
        loading = false;

    $.autopager = function(_options) {
        var autopager = this.autopager;

        var defaults = {
            content: "#content",
            onStart: function() {},
            onComplete: function() {},
            page: 1,
            currentUrl: window.location.href,
            nextUrl: null
        };

        options = $.extend({}, defaults, _options);
        content = $(options.content);
        
        $(window).scroll(function() {
            if (content.offset().top + content.height() < $(document).scrollTop() + $(window).height()) {
                $.autopager.loadNext();
            }
        });

        return this;
    };

    $.extend($.autopager, {
        loadNext: function() {
            if (loading || !options.nextUrl) {
                return;
            }

            loading = true;
            options.onStart();
            $.get(options.nextUrl, insertContent, "text");
            return this;
        }
    });

    function insertContent(res) {
        var json = JSON.parse(res);
        var nextPage = $(json.html);

        options.page = options.page + 1;
        options.currentUrl = options.nextUrl;
        options.nextUrl = json.next;
        content.append(nextPage);
        options.onComplete();
        loading = false;
    }
})(jQuery);
