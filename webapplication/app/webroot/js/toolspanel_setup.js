/*
set up the tools panels
*/
$(function() {
    var tools = $('#toolspanel .tool');

    // go through each tool panel and add opne/close behaviour to the header
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

    //
    // close all the tools that wanted to start closed
    //

    var fx = jQuery.fx.off; // disable fx animation
    jQuery.fx.off = true;
    var closetools = $('#toolspanel .tool.startclosed');
    closetools.each( function(index, tool) {
        // click the header of each tool to close it
        $(tool).children('h1').first().click();
    });
    // restore fx animation
    jQuery.fx.off = fx;

    //
    // set up the mode switching stuff
    //

    $('#button_current').click( function(e) {
        if (Edgar.mapmode !== 'current') {
            $(Edgar.map).trigger('changemode', 'current');
        }
    });

    $('#button_future').click( function(e) {
        if (Edgar.mapmode !== 'future') {
            $(Edgar.map).trigger('changemode', 'future');
        }
    });

    $('#button_vetting').click( function(e) {
        if (Edgar.mapmode !== 'vetting') {
            $(Edgar.map).trigger('changemode', 'vetting');
        }
    });

});
