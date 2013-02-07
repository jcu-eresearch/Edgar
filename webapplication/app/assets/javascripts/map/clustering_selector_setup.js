// ------------------------------------------------------------------
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
});
// ------------------------------------------------------------------
// keep track of layers loading
var layersLoading = [];
// ------------------------------------------------------------------
// attaches layer loading and done-loading events so we can indicate loading
function registerLayerProgress(layer, layerName) {
/*
    // find the layerswitcher
    var ls = map.getControlsByClass('OpenLayers.Control.LayerSwitcher')[0];

    layer.events.register('loadstart', layer, function() {

        // find the label for this layer
        layerIndicator = $.grep(ls.dataLayers, function(dl, index) {
            return (dl.layer === layer);
        });
        // add a 'loading' class to that label span
        if (layerIndicator && layerIndicator.length > 0) {
            $(layerIndicator[0].labelSpan).removeClass('notloading');
        }

        layersLoading.push(layerName);
        loadingChanged();
    });

    layer.events.register('loadend', layer, function() {

        // find the label for this layer
        layerIndicator = $.grep(ls.dataLayers, function(dl, index) {
            return (dl.layer === layer);
        });
        // add a 'loading' class to that label span
        if (layerIndicator && layerIndicator.length > 0) {
            $(layerIndicator[0].labelSpan).addClass('notloading');
        }

        layersLoading.splice( $.inArray(layerName, layersLoading), 1 );
        loadingChanged();
    });
*/
}
// ------------------------------------------------------------------
function loadingHappening() {
    count = layersLoading.length;
    return count;
}
// ------------------------------------------------------------------
function pulseMap() {
    $('#map').animate(
        { opacity: 0.75 },
        400,
        'easeInOutQuad',
        function(){
            $('#map').animate(
                { opacity: 1 },
                400,
                'easeInOutQuad'
            )
        });
}
// ------------------------------------------------------------------
var showingLoading = false;
var pulseId = 0;
// ------------------------------------------------------------------
function indicateLoading() {
    if (loadingHappening() == 0) {
        // then stop!
        showingLoading = false;
        $('#spinner').hide();
    } else {
        pulseMap();
        pulseId = setTimeout(function() { indicateLoading(); }, 800);
    }
}
// ------------------------------------------------------------------
function loadingChanged() {
    if (loadingHappening() == 0) {
        // then stop!
        showingLoading = false;
        $('#spinner').hide();
        clearTimeout(pulseId);
    } else {
        if (showingLoading == false) {
            showingLoading = true;
            $('#spinner').show();
//            pulseMap();
//            indicateLoading();
        }
    }
}
// ------------------------------------------------------------------
$(function() {
    // animate the map opacity
//    $('#go').click( function() {
//        loading();
//    });
});
// ------------------------------------------------------------------
