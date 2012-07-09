$(function() {
    initExistingVettingInterface();
    initNewVettingInterface();

    // test the mode changing stuff
    $('#vet').click( function() {
        $(Edgar.map).trigger('changemode', 'vetting');
    });

    $('#devet').click( function() {
        $(Edgar.map).trigger('changemode', 'current');
    });

});

// get ready to do vetting.  gets called by mapmodes.js, after
// the vetting tools have been switched on
function engageVettingMode() {
}

// wrap up the vetting mode.  gets called by mapmodes.js, before
// the vetting tools have been hidden
function disengageVettingMode() {
}

