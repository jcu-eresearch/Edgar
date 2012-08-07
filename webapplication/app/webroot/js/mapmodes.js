// Edgar's species map is always in one of four mapmodes.
// Read the value if Edgar.mapmode to determine which.
// DON'T WRITE TO Edgar.mapmode.

//
// Changing map mode
// -----------------
// trigger a changemode event to ask to change map modes:
//
//     $(Edgar.map).trigger('changemode', 'modename') to attempt
//
// This will only change modes if all the listeners are okay with it.
//
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
// you can prevent the mode change by calling event.preventDefault()
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
    var validModes = ['blank','current','future','vetting'];
    var $map = $(theMap);
    theMap.destinationMode = 'blank';
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // the eventual change mode function - DON'T CALL THIS
    // if you want to change modes do    $(Edgar.map).trigger('changemode', 'vetting');
    theMap.changemode = function() {
        // what modes are we changing between?
        var oldMode = Edgar.mapmode;
        var newMode = theMap.destinationMode;

        consolelog('changing mode, ' + oldMode + ' to ' + newMode);

        if ( $.inArray(newMode, validModes) == -1 ) {
            consolelog('ERROR: attempt to change map to unrecognised mode "' + newMode + '".');
            consolelog('pretending mode "blank" was selected.');
            newMode = 'blank';
        }

        // do nothing if there was no adjustment of mode
        if (oldMode === newMode) {

            if (newMode == 'blank') {
                // special handling for blank-to-blank, the startup mode switch
                Edgar.util.showhide(
                    ['tool_layers', 'tool_debug', 'tool_layers','tip_no_species'],
                    ['oldvets','myvets','newvet','tool_legend','tool_classlegend','tool_simpleclasslegend','tool_future','button_current','button_future','button_vetting']
                );

            } else if (newMode == 'current') {
                // special handling for changing species when in current mode
                disengageCurrentMode();
                // Edgar.newSpecies is set by the species panel when a new species
                // is selected, then a current-to-current mode switch is triggered.
                // so here we can call _setupNewSpecies to actually switch to the
                // newly selected species.
                _setupNewSpecies();
                Edgar.util.showhide(['currentspecies'],['speciesselector']);
                engageCurrentMode();
            }

            // if we've handled mode-to-samemode, we can bail out
            return;
        }

        //
        // transitions between modes
        //

        // illegal transitions
        if ( (oldMode === 'blank'   && newMode === 'future' ) || // can't skip current
             (oldMode === 'blank'   && newMode === 'vetting') || // can't skip current
             (oldMode === 'future'  && newMode === 'vetting') || // must go through current
             (oldMode === 'vetting' && newMode === 'future' ) || // must go through current
             (newMode === 'blank')                               // can't return to blank
        ) {
            consolelog('illegal mode transition: cannot move from "' + oldMode + '" to "' + newMode + '".');
        }

        if (oldMode === 'blank'   && newMode === 'current') {
            disengageBlankMode();
            // Edgar.newSpecies is set by the species panel when a new species
            // is selected.
            // so here we can call _setupNewSpecies to actually switch to the
            // newly selected species.
            _setupNewSpecies();
            Edgar.util.showhide(['currentspecies','tool_legend','tool_simpleclasslegend','button_future'],['speciesselector']);
            engageCurrentMode();
        }

        if (oldMode === 'current' && newMode === 'future' ) {
            disengageCurrentMode();
            // show & hide the appropriate tools
            Edgar.util.showhide(['tool_legend','tool_future'], ['tool_classlegend']);
            // switch off the current layers
            clearExistingSpeciesOccurrencesAndSuitabilityLayers();
            engageFutureMode();
        }

        if (oldMode === 'current' && newMode === 'vetting') {
            disengageCurrentMode();
            // show & hide the appropriate tools
//            Edgar.util.showhide(['newvet','oldvets','myvets'], ['tool_legend','tool_future']);
            Edgar.util.showhide(['tool_classlegend','newvet'], ['tool_legend','tool_future','tool_simpleclasslegend']);
            Edgar.vetting.engageVettingMode();
        }

        if (oldMode === 'future'  && newMode === 'current') {
            disengageFutureMode();
            Edgar.util.showhide(['currentspecies','tool_legend','tool_classlegend'], ['tool_future','speciesselector']);
            _setupNewSpecies();
            addSpeciesOccurrencesAndSuitabilityLayers();
            engageCurrentMode();
        }

        if (oldMode === 'vetting' && newMode === 'current') {
            Edgar.vetting.disengageVettingMode();
            _setupNewSpecies();
//            Edgar.util.showhide(['currentspecies','tool_legend'], ['oldvets','newvet','myvets','speciesselector']);
            Edgar.util.showhide(['currentspecies','tool_simpleclasslegend'], ['newvet','speciesselector','tool_legend']);
            engageCurrentMode();
        }

        // yay, we're almost done.. now change the mode record
        Edgar.mapmode = newMode;

        // finally, trigger the event that tells everyone about the new mode
        $map.trigger('modechanged', oldMode);

    }
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // bind a handler to remember the destination mode for later
    $map.on('changemode', function(event, newMode) {
        theMap.destinationMode = newMode;
    });
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    // now that the map has mode changing, trigger a change tob
    // blank mode to get everything set up nicely
    $map.trigger('changemode', 'blank');
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

//
// mode engagements.  maybe should be in files of their own..
//

// ------------------------------------------------------------------
// gets called by mapmodes.js, when changing out of blank mode
function disengageBlankMode() {
    Edgar.util.showhide([],['tip_no_species']);
}
// ------------------------------------------------------------------
// gets called by mapmodes.js, when the previous mode has been
// disengeged, and the current mode tools have been shown
function engageCurrentMode() {
    Edgar.util.showhide(['button_future'],[]);
    if (Edgar.user != null) {
        Edgar.util.showhide(['button_vetting'],[]);
    }
    // clear the "destination" species
    Edgar.newSpecies = null;
}
// ------------------------------------------------------------------
// gets called by mapmodes.js, when changing out of current 
// mode, before hiding the current mode tools
function disengageCurrentMode() {
    Edgar.util.showhide([],['button_vetting','button_future']);
}





