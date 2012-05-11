$(function() {
    var tools = $('#toolspanel .tool');
    tools.each( function(index, tool) {
        tool = $(tool);
        var header = $(tool).children('h1').first();
        var body = tool.children('.toolcontent').first();
        header.click( function() {
            body.toggle('blind', 'fast');
            return false;
        });
    });
});
