// ------------------------------------------------------------------
// gets called by mapmodes.js, when the previous mode has been
// disengeged, and the future mode tools have been shown
function engageFutureMode() {
    Edgar.util.showhide(['button_current'],[]);
    Edgar.yearSlider.setSpeciesId(Edgar.mapdata.species.id);
    Edgar.yearSlider.setScenario();
}
// ------------------------------------------------------------------
// gets called by mapmodes.js, when changing out of future 
// mode, before hiding the future mode tools
function disengageFutureMode() {
    Edgar.util.showhide([],['button_current']);
    Edgar.yearSlider.setSpeciesId(null);
}
// ------------------------------------------------------------------
// ------------------------------------------------------------------
$(function() {
    //
    // set up the emission selecting stuff
    //
    Edgar.yearSlider = new Edgar.YearSlider({
        containerElem: '#tool_future .options_container',
        loadingContainerElem: '#tool_future .loading_container',
        sliderElem: '#year_slider',
        scenarioElemName: 'scenario',
        map: Edgar.map,
        loadingBar: '#tool_future .loading_bar',
        yearLabelElem: '#year_label'
    });

    Edgar.mapdata.emissionScenario = $('#emission_scenarios').val();
    Edgar.mapdata.year = parseInt($('#year_selector').val());

    $('#play_slider_button').click(function(){
        Edgar.yearSlider.playAnimation();
    });

});
// ------------------------------------------------------------------
