// ------------------------------------------------------------------
// stuff to do on the species panel
// ------------------------------------------------------------------
function changeSpecies(species) {
    // The work to do if the user changes the selected species..
    // We need to then update the species details.

    clearExistingSpeciesOccurrencesAndDistributionLayers();

    Edgar.map.species = species;

    if (species !== null) {

        addSpeciesOccurrencesAndDistributionLayers();

        $('#species_autocomplete').val(species.label);

        var statusText = "";
        if (species.numDirtyOccurrences < 1) {
            statusText = statusText + 'modelling for this species is up to date';
        } else {
            statusText = statusText + species.numDirtyOccurrences + ' records have changed since the last modelling run';
        }

        $('#model_status').text(species.remodelStatus);

        if(Edgar.user && Edgar.user.canRequestRemodel && species.canRequestRemodel){
            $('#model_rerun_button').show();
            $('#model_rerun_requested').hide();
            $('#model_rerun').show();
        } else {
            $('#model_rerun').hide();
        }
        $('#species_modelling_status').text(statusText);
    } else {
        $('#species_autocomplete').val('');
        $('#species_freshness').text('');
        $('#model_status').text('');
        $('#model_rerun').hide();
    }
    updateWindowHistory();
}
// ------------------------------------------------------------------
function updateSpeciesShowingLabel() {
    setTimeout(function() {
        var selector = $('#species_autocomplete');
        if (Edgar.map.species === null) {
            $('#species_showing_label').text('choose a species for display');
        } else {
            $('#species_showing_label').text('now showing');
        }
    }, 0);
}
// ------------------------------------------------------------------
$(function() {

    $('#species_autocomplete').focus( function() {
        // when the _text_box_ is focussed
        updateSpeciesShowingLabel();
        setTimeout(function() {
            $('#species_autocomplete').select();
        }, 0);
    });

    $('#species_autocomplete').autocomplete({
        minLength: 2,
        source: Edgar.baseUrl + 'species/autocomplete.json',
        select: function(event, ui) {
            changeSpecies(ui.item);
            updateSpeciesShowingLabel();
        }
    });

    $('#model_rerun_button').click(function() {
        $.ajax({ url: Edgar.baseUrl + 'species/request_model_rerun/' + Edgar.map.species.id });
        $(this).fadeOut('fast', function(){
            $('#model_rerun_requested').fadeIn();
        });
    });

    //load species if specified
    if (mapSpecies !== null) {
        changeSpecies(mapSpecies);
    }

    updateSpeciesShowingLabel();
});
// ------------------------------------------------------------------
// ------------------------------------------------------------------

