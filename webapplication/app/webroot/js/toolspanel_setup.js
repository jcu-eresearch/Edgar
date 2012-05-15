$(function() {
    var tools = $('#toolspanel .tool');
    tools.each( function(index, tool) {
        tool = $(tool);
        var header = $(tool).children('h1').first();
        var body = tool.children('.toolcontent').first();
        header.disableSelection();
        header.click( function() {
            header.toggleClass('closed');
            body.toggle('blind', 'fast');
            return false;
        });
    });
});
