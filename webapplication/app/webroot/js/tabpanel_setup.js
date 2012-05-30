$(function() {

    var width_of_panel = 0.8; // <<< edit this if you change the panel width in the css
    var w_o_p_percent = width_of_panel * 100 + '%';

    // - - - - - - - - - - - - - - - - - - - - - - - - - 
    // jQuery has a problem preserving the widths of the tab
    // pages while they're being hidden.  So this code sets
    // the widths in explicit pixels while the animation is
    // running, then sets it back to a percentage afterward.
    function closetab(tab) {
        tab = $(tab).filter(':visible');
        tab.width(width_of_panel * $('#header').width());
        // close any additionals that were open
        tab.find('.additionalcontent').children('div').hide();
        // finally, slide it closed
        tab.hide('blind', 'fast', function() {
            tab.css('width', w_o_p_percent);
            tab.css('bottom', '');
        });
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - 
    function opentab(tab) {
        tab = $(tab).filter(':hidden');
        tab.width(width_of_panel * $('#header').width());
        tab.show('blind', 'fast', function() {
            tab.css('width', w_o_p_percent);
        });
    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - 

    //
    // deal with tabs
    //
    var tabs = $('.triggeredtab');

    tabs.each( function(index, tab) {
        tab = $(tab);
        tab.hide();

        // maybe there's show-more content in the tab
        additionals = tab.find('.additionalcontent');
        additionals.each( function(index, add) {
            add = $(add);

            var content = add.children('div');
            content.hide();

            var opener = add.children('span');
            opener.click( function(event) {
                if (content.filter(':visible').length > 0) {
                    // ..then we're already open, so close
                    content.hide('blind', 'fast');
                    tab.css('bottom', '');
                } else {
                    // ..we're closed, so open up
                    content.show('blind', 'fast');
                    tab.css('bottom', '1em');
                }
            });
        });
    });
    
    //
    // deal with triggers
    //
    var triggers = $('#tabtriggers li a');
    
    triggers.each( function(index, trigger) {
        trigger = $(trigger);
        var tab = $( '#' + trigger.attr('for') );
        // close each open tab
        trigger.addClass('closed');

        trigger.disableSelection();

        // set up click-trigger-to-open

        trigger.click( function(event) {
            var closedclickedtrigger = $(event.target).filter('.closed');
            var closedclickedtab = $( '#' + closedclickedtrigger.attr('for') );

            // close every tab
            var alltriggers = $('#tabtriggers li a');
            alltriggers.each( function(tindex, trig) {
                $(trig).addClass('closed');
                closetab($('#' + $(trig).attr('for')));
            });

            // re-open the tab that was clicked on, if it started closed
            closedclickedtrigger.removeClass('closed');
            opentab(closedclickedtab);

            return false;
        });
        
    });

});
