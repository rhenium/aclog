//= require _html-autoload
$(function() {
  $(".pagination").hide();
  $.autopager({
    content: ".tweets",
    nextLink: "a[rel=next]",
    onStart: function() {
      $(".loading").show();
    },
    onComplete: function() {
      $(".loading").hide();
    }
  });
});

