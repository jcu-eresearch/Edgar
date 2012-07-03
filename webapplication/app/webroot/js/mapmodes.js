// Edgar's species map is always in one of four mapmodes.
// Read the value if Edgar.mapmode to determine which.
// DON'T WRITE TO Edgar.mapmode.
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
        
        if (oldMode === newMode) {
            return;
        }

        if ( $.inArray(newMode, validModes) == -1 ) {
            consolelog('ERROR: attempt to change map to unrecognised mode "' + newMode + '".');
            consolelog('pretending mode "blank" was selected.');
            newMode = 'blank';
        }

        // okay now we're okay to change to the proper mode.
        consolelog("changing mode to " + newMode);

        //
        // transitions between modes
        //

        // illegal transitions
        if ( (oldMode === 'blank' && newMode === 'future') ||  // can't skip current
             (oldMode === 'blank' && newMode === 'vetting') || // can't skip current
             (newMode === 'blank')
        ) {                           // can't return to blank
            consolelog('illegal mode transition: cannot move from "' + oldMode + '" to "' + newMode + '".');
        }

        if (oldMode === 'blank'   && newMode === 'current') {
        }

        if (oldMode === 'current' && newMode === 'future' ) {
        }

        if (oldMode === 'current' && newMode === 'vetting') {
            // switch off the climate suitability layer
            
        }

        if (oldMode === 'future'  && newMode === 'current') {
        }

        if (oldMode === 'future'  && newMode === 'vetting') {
        }

        if (oldMode === 'vetting' && newMode === 'current') {
        }

        if (oldMode === 'vetting' && newMode === 'future' ) {
        }

    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // bind a handler that remembers the destination mode for later use
    $map.bind('changemode', function(event, newMode) {
        theMap.destinationMode = newMode;
    });
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

