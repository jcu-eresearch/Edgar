$(function() {
    // jQuery will run this when the page has loaded
    var cluster_selector = $('#cluster');
    if (cluster_selector) {
        cluster_selector.change( function() {
            // this will happen when a new cluster choice is selected
            clearExistingSpeciesOccurrencesLayer();
            addOccurrencesLayer();
        });
    }
})
