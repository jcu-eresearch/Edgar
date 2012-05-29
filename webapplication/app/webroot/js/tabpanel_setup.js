$(function() {
    var triggers = $('#tabtriggers li a');
    triggers.each( function(index, trigger) {
        trigger = $(trigger);
        var tab = $( '#' + trigger.attr('for') );
        // close each tab
        tab.filter(':visible').hide('blind', 'slow');
        trigger.addClass('closed');
        // set up click-trigger-to-open
        trigger.disableSelection();

        trigger.click( function(event) {
            var closedclickedtrigger = $(event.target).filter('.closed');
            var closedclickedtab = $( '#' + closedclickedtrigger.attr('for') );
            // close every tab
            var alltriggers = $('#tabtriggers li a');
            alltriggers.each( function(tindex, trig) {
                $(trig).addClass('closed');
                $('#' + $(trig).attr('for') + ':visible').hide('blind', 'fast');
            });
            // re-open the tab that was clicked on, if it started closed
            closedclickedtrigger.removeClass('closed');
            closedclickedtab.show('blind', 'fast');
            return false;
        });
        
    });

});
