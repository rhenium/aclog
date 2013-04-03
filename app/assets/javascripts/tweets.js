//= require jquery.autopager-1.0.0-mod
$(function() {
  $.autopager({
    autoLoad: true,
    content: ".items",
    start: function(current, next) {
      $(".loading").show();
    },
    load: function(current, next) {
      $(".loading").hide();
    }
  });
  $("a[rel=next]").hide().click(function() {
    $.autopager("load");
    return false;
  });
});
