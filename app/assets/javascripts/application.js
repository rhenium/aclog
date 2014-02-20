//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require _widgets
//= require _define_application
//= require_tree .

$(function() {
    var controller = $("body").data("controller");
    var action = $("body").data("action");

    var ac = Application[controller];
    if (ac !== undefined) {
        if (ac["_"] !== undefined) { ac["_"](); }
        if (ac[action] !== undefined) { ac[action](); }
    }
});

