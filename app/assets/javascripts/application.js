//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require _widgets
//= require _define_application
//= require_tree .

$(function() {
    // Layout: User jump
    $("#jump_to_dropdown_toggle").click(function() {
        setTimeout(function() { $("#jump_to_textbox").focus(); }, 0);
    });
    $("#jump_to_form").on("submit", function() {
        $(this).attr("action", "/" + $("#jump_to_textbox").val());
    });
});

$(function() {
    var controller = $("body").data("controller");
    var action = $("body").data("action");

    var ac = Application[controller];
    if (ac !== undefined) {
        if (ac["_"] !== undefined) { ac["_"](); }
        if (ac[action] !== undefined) { ac[action](); }
    }
});

