// Edgar's species map is always in one of four mapmodes.
// Read the value if Edgar.mapmode to determine which.
// DON'T WRITE TO Edgar.mapmode.

// Changing map mode
// -----------------
// call $(Edgar.map).trigger('changemode', 'modename') to attempt
// to change modes.
//
// Overriding / cancelling a mode change
// -------------------------------------
// if you want to be able to override a mode change, bind a handler
// to the changemode event like this:
//
//    $(Edgar.map).on('changemode', function(event, newMode) {
//        console.log('attempt to change mode to ' + newMode);
//    }
//
// you can prevent the mode change by calling event.preventDefault
// in your handler:
//
//    $(Edgar.map).on('changemode', function(event, newMode) {
//        console.log('attempt to change mode from ' +
//                Edgar.mapmode + ' to ' + newMode);
//        if (notReady) {
//            console.log('cancelling mode change.');
//            event.preventDefault();
//        }
//    }
//
// Being notified of a mode change
// -------------------------------
// Because the mode change is overrideable, you can't use the 
// changemode event to react to a mode change.  For that you 
// need to listen for the modechanged event.
//
//    $(Edgar.map).on('modechanged', function(event, oldMode) {
//        console.log('mode has changed from ' + oldMode +
//            ' to ' + Edgar.mapmode);
//    }
//
// What modes are there?
// ---------------------
// The possible modes are:
//
// mapmode: 'blank'
//   No species has been selected yet
//
// mapmode: 'current'
//   A species is selected, and the map is showing the 
//   occurrences and the current climate suitability.
//
// mapmode: 'future'
//   A species is selected, and the map is showing the
//   current and future climate suitability (but no
//   occurrences).
//
// mapmode: 'vetting'
//   A species is selected, a user is logged in, and
//   the user is viewing or editing vetting information.

// -------------------------------------------------------------------------------
// presume the init_setup.js has already run and Edgar.mode
// exists and is initially set to 'blank'.
// e.g.  Edgar.mode = Edgar.mode || 'blank';

// call this function and pass in the map object to get modes working
function addMapModes(theMap) {
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    validModes = ['blank','current','future','vetting'];
    theMap.destinationMode = 'blank';
    $map = $(theMap);
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // the eventual change mode function - DON'T CALL THIS
    // if you want to change modes do    $(Edgar.map).trigger('changemode', 'vetting');
    theMap.changemode = function() {
        // what modes are we changing between?
        var oldMode = Edgar.mapmode;
        var newMode = theMap.destinationMode;

        function showhidetools(showlist, hidelist) { // - - - - - - - - 
            $.each(hidelist, function(i, tool) {
                $('#' + tool).hide('blind','slow');
            });
            $.each(showlist, function(i, tool) {
                $('#' + tool).show('blind','slow');
            });
        } // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        // do nothing if there was no adjustment of mode
        if (oldMode === newMode) {
            if (oldMode == 'blank') {
                // special handling for blank-to-blank, the startup mode switch
                showhidetools(
                    ['tool-layers', 'tool-example', 'tool-debug', 'tool-layers'],
                    ['oldvets','myvets','newvet','tool-legend','tool-emissions']
                );
            }
            return;
        }

        if ( $.inArray(newMode, validModes) == -1 ) {
            consolelog('ERROR: attempt to change map to unrecognised mode "' + newMode + '".');
            consolelog('pretending mode "blank" was selected.');
            newMode = 'blank';
        }

        // okay now we're okay to change to the proper mode.
        consolelog('changing mode, ' + oldMode + ' to ' + newMode);

        //
        // transitions between modes
        //

        // illegal transitions
        if ( (oldMode === 'blank'   && newMode === 'future' ) || // can't skip current
             (oldMode === 'blank'   && newMode === 'vetting') || // can't skip current
             (oldMode === 'future'  && newMode === 'vetting') || // must go through current
             (oldMode === 'vetting' && newMode === 'future' ) || // must go through current
             (newMode === 'blank')
        ) {                           // can't return to blank
            consolelog('illegal mode transition: cannot move from "' + oldMode + '" to "' + newMode + '".');
        }

        if (oldMode === 'blank'   && newMode === 'current') {
        }

        if (oldMode === 'current' && newMode === 'future' ) {
        }

        if (oldMode === 'current' && newMode === 'vetting') {
            disengageCurrentMode();
            // show & hide the appropriate tools
            showhidetools(['oldvets','newvet','myvets'], ['tool-legend','tool-emissions']);
            Edgar.vetting.engageVettingMode();
        }

        if (oldMode === 'future'  && newMode === 'current') {
        }

        if (oldMode === 'vetting' && newMode === 'current') {
            Edgar.vetting.disengageVettingMode();
            showhidetools(['tool-legend'], ['oldvets','newvet','myvets']);
            engageCurrentMode();
        }

        // yay, we're almost done.. now change the mode record
        Edgar.mapmode = newMode;

        // finally, trigger the event that tells everyone about the new mode
        $map.trigger('modechanged', oldMode);

    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // bind a handler that remembers the destination mode for later use
    $map.on('changemode', function(event, newMode) {
        theMap.destinationMode = newMode;
    });
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

$(function() {
    // trigger a mode change to blank, to get everything showing up right
    $(Edgar.map).trigger('changemode', 'blank');

    // test the mode changing stuff
    $('#vet').click( function() {
        $(Edgar.map).trigger('changemode', 'current');
        setTimeout( function() {
            $(Edgar.map).trigger('changemode', 'vetting');
        }, 1000);
    });

    $('#devet').click( function() {
        $(Edgar.map).trigger('changemode', 'current');
    });

});





