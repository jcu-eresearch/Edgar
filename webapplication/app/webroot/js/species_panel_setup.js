// ------------------------------------------------------------------
// stuff to do on the species panel
// ------------------------------------------------------------------
$(function() {
    $(Edgar.map).on('modechanged', _setupNewSpecies);

    // maybe the species is already set on the URL
    if (mapSpecies !== null) {
        setTimeout(function() {
            changeSpecies(mapSpecies);
        }, 1);
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

    // set up the remodel button
    $('#button_remodel').click(function() {
        $.ajax({ url: Edgar.baseUrl + 'species/request_model_rerun/' + Edgar.mapdata.species.id });
        $(this).fadeOut('fast', function() {
            Edgar.mapdata.species.remodelStatus = "Remodelling running";
            updateSpeciesStatus(Edgar.mapdata.species);
        });
    });

    // set up the autocomplete bar
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
            changeSpecies(ui.item);
            Edgar.util.showhide(['currentspecies'],['speciesselector']);
        }
    });

});
// ------------------------------------------------------------------
// update the status information for a species.
function updateSpeciesStatus(species) {

        var status = species.remodelStatus;
        var dirty = species.numDirtyOccurrences;
        var statusText = "";

        // TODO: incorporate dirty-vettings into this status info

        if (status.indexOf("Remodelling running") != -1) {
            statusText = "Model is <em>now running</em> to incorporate ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " for this species."
            $('#button_remodel').hide();
        } else if (status.indexOf("Priority queued") != -1) {
            statusText = "Model is <em>queued</em> to incorporate ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " for this species."
            $('#button_remodel').hide();
        } else if (dirty > 0) {
            statusText = "This species has ";
            statusText += Edgar.util.pluralise(dirty, "changed observation");
            statusText += " <em>not yet incorporated</em>.";
            $('#button_remodel').show();
        } else {
            statusText = 'Climate suitability modelling for this species is <em>up to date</em>.';
            $('#button_remodel').hide();
        }

        $('#currentspecies .status').html(statusText);
}
// ------------------------------------------------------------------
// actually set up for a new species.  Don't call this yourself, use
// changeSpecies(species) which does the mode change checking.
function _setupNewSpecies() {

    if (Edgar.newSpecies && Edgar.newSpecies != Edgar.mapdata.species) {

        consolelog('new species!');

        // set up for the species stored in Edgar.newSpecies
        var oldSpecies = Edgar.mapdata.species;
        var newSpecies = Edgar.newSpecies;

        clearExistingSpeciesOccurrencesAndSuitabilityLayers();
        Edgar.mapdata.species = newSpecies;
        addSpeciesOccurrencesAndSuitabilityLayers();

        // just handle the panel update stuff here.
        // the map updates will be handled in event listeners that
        // listen for the specieschanged event.

        $('#species_autocomplete').val(newSpecies.label);  // set the dropdown's content 
        $('#species_autocomplete').val('');  // set the dropdown's content
        $('#currentspecies h1').text(newSpecies.commonName || '(no common name)');  // set the static panel names
        $('#currentspecies h2').text(newSpecies.scientificName);  // set the static panel names

        updateSpeciesStatus(newSpecies);

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
