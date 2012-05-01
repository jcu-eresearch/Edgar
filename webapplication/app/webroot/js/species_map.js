// Author: Robert Pyke
//
// Assumes that the var species_id, map_tool_url and species_route_url have already been set.
// Assumes that OpenLayer, jQuery, jQueryUI and Google Maps (v2) are all available.

var map, occurrences, distribution, occurrence_select_control, species_distribution_threshold;

// Projections
// ----------

// DecLat, DecLng 
geographic = new OpenLayers.Projection("EPSG:4326");

// Spherical Meters
mercator = new OpenLayers.Projection("EPSG:900913");

// Bounds
// ----------

// Australia Bounds
australia_bounds = new OpenLayers.Bounds();
australia_bounds.extend(new OpenLayers.LonLat(111,-11));
australia_bounds.extend(new OpenLayers.LonLat(152,-43));
australia_bounds = australia_bounds.transform(geographic, mercator);

// The bounds of the world.
// Used to set maxExtent on maps/layers
world_bounds = new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34)

// Where to zoom the map to on start.
zoom_bounds = australia_bounds;

// Edgar bing api key.
// (registered under Robert's name)
var bing_api_key = "AkQSoOVJQm3w4z5uZeg1cPgJVUKqZypthn5_Y47NTFC6EZAGnO9rwAWBQORHqf4l";

function speciesGeoJSONURL() {
    return (species_route_url + "/geo_json_occurrences/" + species_id + ".json");
}

function legendURL() {
    var data = (species_sci_name_cased + '/outputs/' + species_sci_name_cased + '.asc');
    return map_tool_base_url + 'legend_with_threshold.php?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetLegendGraphic&MAP=edgar_master.map&DATA=' + data +
        '&THRESHOLD=' + species_distribution_threshold;
}

function updateSpeciesInfo(callback) {
    $.getJSON(species_route_url + '/minimal_view/' + species_id + '.json', function(data) {
        species_common_name = data['Species']['common_name'];
        species_distribution_threshold = data['Species']['distribution_threshold'];
        if ( callback != undefined ) {
            callback();
        }
    });
}

function updateLegend() {
/*
    $('#map_legend_img').attr('src', legendURL());
*/
}

function showLegend() {
/*
    $('#map_legend_img').show();
*/
}

function hideLegend() {
    $('#map_legend_img').hide();
}

// Removes the old layers..
// Adds the new fresh layers.
// Unfortunately, the bbox/http strategy doesn't allow the URL to be updated on
// the fly, so we have to replace our old layers.
function clearExistingSpeciesOccurrencesAndDistributionLayers() {

    clearExistingSpeciesOccurrencesLayer();
    
    if (distribution !== undefined) {
        map.removeLayer(distribution);
        distribution = undefined;
    }

    // Get rid of any popups the user may of had on screen.
    clearMapPopups();
    hideLegend();
}

function clearExistingSpeciesOccurrencesLayer() {
    // Remove old layers.
    if (occurrences !== undefined) {
        map.removeLayer(occurrences);
        occurrences = undefined;
    }

    // Remove the old occurrence select control.
    if (occurrence_select_control !== undefined) {
        occurrence_select_control.unselectAll();
        occurrence_select_control.deactivate();
        map.removeControl(occurrence_select_control);
        occurrence_select_control = undefined;
    }
}

// Add our species specific layers.
function addSpeciesOccurrencesAndDistributionLayers() {
    updateSpeciesInfo(function() {
        addOccurrencesLayer();
        addDistributionLayer();
        updateLegend();
        showLegend();
    });
}

function clearMapPopups() {
    $.each(map.popups, function(index, popup) {
        map.removePopup(popup);
    });
}

function addDistributionLayer() {
/*
    // Species Distribution
    // ----------------------

    // Our distribution map layer.
    //
    // NOTE:
    // -----
    //
    // This code may need to be updated now that we are using mercator.
    // I believe that OpenLayers will send the correct projection request
    // to Map Server. I also believe that map script will correctly process the
    // projection request.
    // I could be wrong though...
    distribution = new OpenLayers.Layer.WMS(
        "Distribution",
        map_tool_base_url + 'map_with_threshold.php', // path to our map script handler.

        // Params to send as part of request (note: keys will be auto-upcased)
        // I'm typing them in caps so I don't get confused.
        {
            MODE: 'map', 
            MAP: 'edgar_master.map',
            DATA: (species_sci_name_cased + '/outputs/' + species_sci_name_cased + '.asc'),
            SPECIESID: species_id,
            REASPECT: "true",
            TRANSPARENT: 'true',
            THRESHOLD: species_distribution_threshold
        },
        {
            // It's an overlay
            isBaseLayer: false,
            transitionEffect: 'resize',
            singleTile: true,
            ratio: 1.5,
        }
    );

    map.addLayer(distribution);
*/
}

function addOccurrencesLayer() {
        // Occurrences Layer
        // -----------------

        // See: http://geojson.org/geojson-spec.html For the GeoJSON spec.
        var occurrences_format = new OpenLayers.Format.GeoJSON({
// No need to convert..
// Looks like having a layer projection of geographic,
// and a map projection of mercator (displayProjection of geographic)
// means that OpenLayers is taking care of it..
//
//          'internalProjection': geographic,
//          'externalProjection': geographic 
        });

        // The styles for our occurrences / cluster points

        var occurrence_StyleMap = new OpenLayers.StyleMap({
            'default': {
                'fillColor': "#993344",
                'strokeColor': "#993344",
                'fillOpacity': 0.8,
                'strokeOpacity': 0.8,
                'fontFamily': 'sans-serif',
                'fontSize': '13px',
            },
            'select': {
                'fillColor': "#83aeef",
                'strokeColor': "#000000",
                'fillOpacity': 0.9,
                'strokeOpacity': 0.9
            }
        });

        var occurrence_render_styles = {
            'dotradius': {
                'pointRadius': "${point_radius}",
            },
            'dotgrid': {
                'pointRadius': "${point_radius}",
            },
            'squaregrid': {
                'label': "${label}",
                'fontOpacity': 1.0,
                'fillOpacity': 0.25,
                'strokeOpacity': 0.75,
            },
        }
        occurrence_StyleMap.addUniqueValueRules("default", "occurrence_type", occurrence_render_styles);
        occurrence_StyleMap.addUniqueValueRules("select", "occurrence_type", occurrence_render_styles);

        var cluster_size_render_styles = {
            'large': {
//                'fontWeight': 'medium',
//                'fontSize': '12px',
                'fontWeight': 'bold',
                'fontSize': '13px',
            },
            'medium': {
                'fontWeight': 'medium',
                'fontSize': '12px',
            },
            'small': {
                'fontWeight': 'medium',
                'fontSize': '11px',
            },
        }
        occurrence_StyleMap.addUniqueValueRules("default", "cluster_size", cluster_size_render_styles);
        occurrence_StyleMap.addUniqueValueRules("select", "cluster_size", cluster_size_render_styles);
        
        // set the clustering to use for this occurrences layer
        cluster_strategy = "none";
        cluster_selector = document.getElementById("cluster");
        if (cluster_selector) {
            cluster_strategy = cluster_selector.options[cluster_selector.selectedIndex].value;
        }

        // The occurrences layer
        // Makes use of the BBOX strategy to dynamically load occurrences data.
        occurrences = new OpenLayers.Layer.Vector(
            "Occurrences", 
            {
                // It's an overlay
                isBaseLayer: false,

                // our occurrence vector data is geographic (DecLat & DecLng)
                projection: geographic,

                // resFactor determines how often to update the map.
                // See: http://dev.openlayers.org/docs/files/OpenLayers/Strategy/BBOX-js.html#OpenLayers.Strategy.BBOX.resFactor
                // A setting of <= 1 will mean the map is updated every time its zoom/bounds change.
//                strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})],
                strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})],
                protocol: new OpenLayers.Protocol.HTTP({
                    // Path to the geo_json_occurrences for this species.
                    url: speciesGeoJSONURL(),
                    params: {
                        // Place addition custom request params here..
                        bound: true,                 // do bound the request
                        clustered: cluster_strategy  // use whatever clustering
                    },

                    // The data format
                    format: occurrences_format,
                }),

                // the layer style
                styleMap: occurrence_StyleMap,
            }

        );

        // Set the opacity of the layer using setOpacity 
        //
        // NOTE: Opacity is not supported as an option on layer..
        // so don't even try it. Setting it on the layer will cause
        // undesirable behaviour where the map layer will think the opacity 
        // has been updated when it hasn't. Worse yet, if you then
        // try and run setOpacity after specifying the opacity property on
        // the layer, it won't appear to do anything. This is because OpenLayers
        // tries to be smart, it will check if layer.opacity is different
        // to your setOpacity arg, and will determine that they haven't changed
        // and so will do nothing..
        occurrences.setOpacity(1.0);

        // Occurrence Feature Selection (on-click or on-hover)
        // --------------------------------------------------

        // what to do when the user presses close on the pop-up.
        function onPopupClose(evt) {
            // 'this' is the popup.
            occurrence_select_control.unselectAll();
        }

        // what to do when the user clicks a feature
        function onFeatureSelect(evt) {
            feature = evt.feature;
            popup = new OpenLayers.Popup.FramedCloud(
                "featurePopup",
                feature.geometry.getBounds().getCenterLonLat(),
                new OpenLayers.Size(100,100),
                "<h2>" + feature.attributes.title + "</h2>" +
                feature.attributes.description,
                null, true, onPopupClose);
                feature.popup = popup;
                popup.feature = feature;
                map.addPopup(popup);
        }

        // what to do when a feature is no longed seected
        function onFeatureUnselect(evt) {
            feature = evt.feature;
            if (feature.popup) {
                popup.feature = null;
                map.removePopup(feature.popup);
                feature.popup.destroy();
                feature.popup = null;
            }
        }

        // Associate the above functions with the appropriate callbacks
        occurrences.events.on({
            'featureselected': onFeatureSelect,
            'featureunselected': onFeatureUnselect
        });

        // Clear any popups when the zoom changes.
        // If we don't do this, the popup can become stuck (can't be closed).
        map.events.on({
            'zoomend': clearMapPopups
        });

        // Specify the selection control for the occurrences layer.
        //
        // Note: change hover to true to make it a on hover interaction (instead
        // of an on-click interaction)
        occurrence_select_control = new OpenLayers.Control.SelectFeature(
            occurrences, {hover: false}
        );

        map.addLayer(occurrences);

        map.addControl(occurrence_select_control);
        occurrence_select_control.activate();

}

$(document).ready(function() {

    function changeSpecies(new_species_id, sci_name){
        console.log("Changing species to " + sci_name);

        // Only update the map if the user chose an actual species.
        // the 'choose one' option has no value.
        if (new_species_id !== '') {
                species_id = new_species_id;
                species_sci_name_cased = sci_name;
                species_sci_name_cased = $.trim(species_sci_name_cased);
                species_sci_name_cased = species_sci_name_cased.replace(/\./g, '');
                species_sci_name_cased = species_sci_name_cased.replace(/\s/g, '_');
                var new_species_name = $('#SpeciesSpeciesId').val();

                clearExistingSpeciesOccurrencesAndDistributionLayers();
                addSpeciesOccurrencesAndDistributionLayers();
        } else {
            clearExistingSpeciesOccurrencesAndDistributionLayers();
        }
    }

    $('#species_autocomplete').autocomplete({
        minLength: 2,
        source: Edgar.baseURL + 'species/autocomplete.json',
        select: function(event, ui) {
            changeSpecies(ui.item.id, ui.item.value);
        }
    });

    // The work to do if the user changes the selected species..
    // We need to change the species_sci_name_cased for the dist layer.
    // We need to then update the species details.
    $('#SpeciesSpeciesId').change(function(evt) {
        var new_species_id = $('#SpeciesSpeciesId').val();
        var sci_name = $('#SpeciesSpeciesId option:selected').text();
        changeSpecies(new_species_id, sci_name);
    });



    // The Map Object
    // ----------

    map = new OpenLayers.Map('map', {
        projection: mercator,
        displayProjection: geographic,
        units: "m",
        maxResolution: 156543.0339,
        maxExtent: world_bounds

        // Setting the restrictedExtent will change the bounds
        // that pressing the 'world' icon zooms to.
        // User can manually zoom out past this point.
//            restrictedExtent: zoom_bounds

    });


    // VMap0
    // ----------

    // The standard open layers VMAP0 layer.
    // A public domain layer.
    // Read about this layer here: http://earth-info.nga.mil/publications/vmap0.html
    // and here: http://en.wikipedia.org/wiki/Vector_map#Level_Zero_.28VMAP0.29
    var vmap0 = new OpenLayers.Layer.WMS(
        "World Map (VMAP0)",
        "http://vmap0.tiles.osgeo.org/wms/vmap0",
        {
            'layers':'basic',
        }
    );


    // Open Street Map
    // ----------------

    // The Open Street Map layer.
    // See more here: http://wiki.openstreetmap.org/wiki/Main_Page
    // and specifically here: http://wiki.openstreetmap.org/wiki/OpenLayers
    var osm = new OpenLayers.Layer.OSM(
        "Open Street Map"
    );


    // Google Maps Layers
    // --------------------
    //
    // requires google maps v2 (with valid API key)

    // Google Physical layer
    var gphy = new OpenLayers.Layer.Google(
            "Google Physical",
            {
                type: G_PHYSICAL_MAP,
                'sphericalMercator': true,
                'maxExtent': world_bounds
            }
    );

    // Google Streets layer
    var gmap = new OpenLayers.Layer.Google(
            "Google Streets",
            {
                numZoomLevels:20,
                'sphericalMercator': true,
                'maxExtent': world_bounds
            }
    );

    // Google Hybrid layer
    var ghyb = new OpenLayers.Layer.Google(
            "Google Hybrid",
            {
                type: G_HYBRID_MAP,
                'sphericalMercator': true,
                'maxExtent': world_bounds
            }
    );

    // Google Satellite layer
    var gsat = new OpenLayers.Layer.Google(
            "Google Satellite",
            {
                type: G_SATELLITE_MAP,
                numZoomLevels: 22,
                'sphericalMercator': true,
                'maxExtent': world_bounds
            }
    );


    // Bing Maps Layers
    // --------------------
    //
    // Requires bing_api_key to be set
    // More info and registration here: http://bingmapsportal.com/

    // Bing Road layer
    var bing_road = new OpenLayers.Layer.Bing({
        name: "Bing Road",
        key: bing_api_key,
        type: "Road"
    });

    // Bing Hybrid layer
    var bing_hybrid = new OpenLayers.Layer.Bing({
        name: "Bing Hybrid",
        key: bing_api_key,
        type: "AerialWithLabels"
    });

    // Bing Aerial layer
    var bing_aerial = new OpenLayers.Layer.Bing({
        name: "Bing Aerial",
        key: bing_api_key,
        type: "Aerial"
    });



    // Map - Final Setup
    // -------------

    // Add the standard set of map controls
//    map.addControl(new OpenLayers.Control.Permalink());
    map.addControl(new OpenLayers.Control.MousePosition());

    // Let the user change between layers
//    layer_switcher = new OpenLayers.Control.ExtendedLayerSwitcher();
    layer_switcher = new OpenLayers.Control.LayerSwitcher();
//    layer_switcher.roundedCornerColor = "#090909";
    layer_switcher.ascending = false;
    layer_switcher.useLegendGraphics = false;

    map.addControl(layer_switcher);
//    layer_switcher.maximizeControl();

    // Add our layers
//        map.addLayers([gphy, gmap, ghyb, gsat, bing_road, bing_hybrid, bing_aerial, osm, vmap0, occurrences]);
//    map.addLayers([gphy, gmap, ghyb, gsat, bing_road, bing_hybrid, bing_aerial, osm, vmap0]);
    map.addLayers([vmap0, osm, bing_aerial, bing_hybrid, bing_road, gsat, ghyb, gmap, gphy]);
    map.setBaseLayer(gphy);

    // Zoom the map to the zoom_bounds specified earlier
    map.zoomToExtent(zoom_bounds);

    if (species_id !== undefined && species_sci_name_cased !== undefined) {
        addSpeciesOccurrencesAndDistributionLayers();
    }

    addLegend();

});

function addLegend() {
}

