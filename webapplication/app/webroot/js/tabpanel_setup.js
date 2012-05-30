$(function() {
    var triggers = $('#tabtriggers li a');
    triggers.each( function(index, trigger) {
        trigger = $(trigger);
        var tab = $( '#' + trigger.attr('for') );
        // close each open tab
        tab.filter(':visible').hide('blind', 'fast');
        trigger.addClass('closed');
        // set up click-trigger-to-open
        trigger.disableSelection();

        // jQuery has a problem preserving the widths of the tab
        // pages while they're being hidden.  So lots of this code
        // sets the widths in explicit pixels while the animation is
        // running, then sets it back to a percentage afterward.

        trigger.click( function(event) {
            var closedclickedtrigger = $(event.target).filter('.closed');
            var closedclickedtab = $( '#' + closedclickedtrigger.attr('for') );
            // close every tab
            var alltriggers = $('#tabtriggers li a');
            alltriggers.each( function(tindex, trig) {
                $(trig).addClass('closed');
                var thetab = $('#' + $(trig).attr('for') + ':visible');
                if (thetab.length > 0) {
                    // explicitly set the tab's width
                    thetab.width(0.7 * $('#header').width());
                    // then hide
                    thetab.hide('blind', 'fast', function() {
                        // then change width back to percentage
                        thetab.css('width', '70%');
                    });
                }

            });
            // re-open the tab that was clicked on, if it started closed
            closedclickedtrigger.removeClass('closed');

            closedclickedtab.width(0.7 * $('#header').width());
            closedclickedtab.show('blind', 'fast', function() {
                closedclickedtab.css('width', '70%');
            });

            return false;
        });
        
    });

});
