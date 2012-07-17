// ------------------------------------------------------------------
// stuff to do on the species panel
// ------------------------------------------------------------------
$(function() {
    $(Edgar.map).on('modechanged', _setupNewSpecies);

    // maybe the species is already set on the URL
    if (mapSpecies !== null) {
        setTimeout(function() {changeSpecies(mapSpecies);}, 1);
    }

    // set up the cancel button
    $('#button_cancelselect').click(function(e) {
        $('#speciesselector').hide('blind');        
    });

    // hide the cancel button if we start blank
    if (Edgar.mapmode === 'blank') {
        $('#button_cancelselect').hide();
    }

    // set up the change-species button
    $('#button_changespecies').click(function(e) {
        $('#button_cancelselect').show();
        $('#speciesselector').show('blind');
        $('#species_autocomplete').focus().select();
        $('#species_autocomplete').val('');
    });
});
// ------------------------------------------------------------------
// actually set up for a new species.  Don't call this yourself, use
// changeSpecies(species) which does the mode change checking.
function _setupNewSpecies() {

    if (Edgar.mapmode === 'current' && Edgar.newSpecies != Edgar.mapdata.species) {

        consolelog('new species!');

        // set up for the species stored in Edgar.newSpecies
        var oldSpecies = Edgar.mapdata.species;
        var newSpecies = Edgar.newSpecies;

        clearExistingSpeciesOccurrencesAndDistributionLayers();
        Edgar.mapdata.species = newSpecies;
        addSpeciesOccurrencesAndDistributionLayers();

        // just handle the panel update stuff here.
        // the map updates will be handled in event listeners that
        // listen for the specieschanged event.

        $('#species_autocomplete').val(newSpecies.label);  // set the dropdown's content 
        $('#species_autocomplete').val('');  // set the dropdown's content
        $('#currentspecies h1').text(newSpecies.commonName || '(no common name)');  // set the static panel names
        $('#currentspecies h2').text(newSpecies.scientificName);  // set the static panel names

        var status = newSpecies.remodelStatus;
        var dirty = newSpecies.numDirtyOccurrences;
        var statusText = "";

        if (status.indexOf("Remodelling running") != -1) {
            statusText = "Modelling is <em>now running</em> to incorporate ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " into the climate suitability for this species."
            // TODO hide queue-now button
        } else if (status.indexOf("Priority queued") != -1) {
            statusText = "Modelling is <em>queued</em> to incorporate ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " into the climate suitability for this species."
            // TODO hide queue-now button
        } else if (dirty > 0) {
            statusText = "There are ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " <em>not yet incorporated</em> into the climate";
            statusText += " suitability for this species.";
            // TODO show queue-now button
        } else {
            statusText = 'Climate suitability modelling for this species is <em>up to date</em>.';
            // TODO hide queue-now button
        }

        $('#currentspecies .status').html(statusText);

        updateWindowHistory();

        Edgar.newSpecies = null;

        $(Edgar.map).trigger('specieschanged', oldSpecies);
    }
}
// ------------------------------------------------------------------
function changeSpecies(species) {
    if (species) {
        Edgar.newSpecies = species;
        $(Edgar.map).trigger('changemode', 'current');
    } else {
        consolelog('change requested to a null species - no action taken.');
    }
}
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------








// OLD ////////////////////////



function oldChangeSpecies(species) {
    // The work to do if the user changes the selected species..
    // We need to then update the species details.

    clearExistingSpeciesOccurrencesAndDistributionLayers();

    Edgar.mapdata.species = species;

//consolelog(species);

    if (species !== null) {

        addSpeciesOccurrencesAndDistributionLayers();

        $('#species_autocomplete').val(species.label);

        if(Edgar.user && Edgar.user.canRequestRemodel && species.canRequestRemodel){
            $('#model_rerun_button').show();
            $('#model_rerun_requested').hide();
            $('#model_rerun').show();
        } else {
            $('#model_rerun').hide();
        }

    } else {

        $('#species_autocomplete').val('');
        $('#species_freshness').text('');
        $('#model_status').text('');
        $('#model_rerun').hide();

    }
    updateWindowHistory();
}

// ------------------------------------------------------------------
$(function() {

    $('#species_autocomplete').focus( function() {
        // when the _text_box_ is focussed
        setTimeout(function() {
            $('#species_autocomplete').select();
        }, 0);
    });

    $('#species_autocomplete').autocomplete({
        minLength: 2,
        source: Edgar.baseUrl + 'species/autocomplete.json',
        select: function(event, ui) {
//            oldChangeSpecies(ui.item);
            changeSpecies(ui.item);
        }
    });
/*
    $('#model_rerun_button').click(function() {
        $.ajax({ url: Edgar.baseUrl + 'species/request_model_rerun/' + Edgar.mapdata.species.id });
        $(this).fadeOut('fast', function(){
            $('#model_rerun_requested').fadeIn();
        });
    });
*/
    //load species if specified

});
// ------------------------------------------------------------------
// ------------------------------------------------------------------

