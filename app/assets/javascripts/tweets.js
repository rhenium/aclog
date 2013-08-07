//= require html-autoload
$(function() {
  $(".pagination").hide();
  $.autopager({
    content: $(".tweets"),
    nextUrl: $("a[rel=next]").attr("href"),
    onStart: function() {
      $(".loading").show();
    },
    onComplete: function() {
      $(".loading").hide();
    }
  });
});

