//= require jquery.autopager-1.0.0-mod
$(function() {
  $(".pagination").hide();
  $.autopager({
    autoLoad: true,
    content: ".tweets",
    start: function(current, next) {
      $(".loading").show();
    },
    load: function(current, next) {
      $(".loading").hide();
    }
  });
  $("a[rel=next]").click(function() {
    $.autopager("load");
    return false;
  });
});
