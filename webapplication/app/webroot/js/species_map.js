// Author: Robert Pyke
//
// Assumes that the var mapSpecies, mapToolBaseUrl have already been set.
// Assumes that OpenLayer, jQuery, jQueryUI and Google Maps (v2) are all available.
//

// convenient debug method
function consolelog() { if (window.console){ console.log.apply(console, arguments); } }


var occurrences, distribution, occurrence_select_control, vettingLayer, vettingLayerControl;

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
    return (Edgar.baseUrl + "species/geo_json_occurrences/" + Edgar.mapdata.species.id + ".json");
}

function legendURL() {
    var speciesId = Edgar.mapdata.species.id;
    var data = speciesId + '/1975.asc';
    return mapToolBaseUrl + 'wms_with_auto_determined_threshold.php' +
        '?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetLegendGraphic&MAP=edgar_master.map&DATA=' + data;

}

function updateLegend() {
    $('#map_legend_img').attr('src', legendURL());
}

function showLegend() {
    $('#map_legend_img').show();
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
        Edgar.map.removeLayer(distribution);
        distribution = undefined;
    }

    // Get rid of any popups the user may of had on screen.
    clearMapPopups();
    hideLegend();
}

function clearExistingSpeciesOccurrencesLayer() {
    // Remove old layers.
    if (occurrences !== undefined) {
        Edgar.map.removeLayer(occurrences);
        occurrences = undefined;
    }

    // Remove the old occurrence select control.
    if (occurrence_select_control !== undefined) {
        occurrence_select_control.unselectAll();
        occurrence_select_control.deactivate();
        Edgar.map.removeControl(occurrence_select_control);
        occurrence_select_control = undefined;
    }

    if(vettingLayer !== undefined) {
        console.log('Removing vetting layer');
        Edgar.map.removeLayer(vettingLayer);
        vettingLayerControl.unselectAll();
        vettingLayerControl.deactivate();
        Edgar.map.removeControl(vettingLayerControl);
        vettingLayer = undefined;
        vettingLayerControl = undefined;
    }
}

// Add our species specific layers.
function addSpeciesOccurrencesAndDistributionLayers() {
    addVettingLayer();
    addOccurrencesLayer();
    addDistributionLayer();
    updateLegend();
    showLegend();
}

function clearMapPopups() {
    $.each(Edgar.map.popups, function(index, popup) {
        Edgar.map.removePopup(popup);
    });
}

function reloadDistributionLayers() {
    if (distribution !== undefined) {
        Edgar.map.removeLayer(distribution);
        distribution = undefined;
    }
    addDistributionLayer();
}

function addDistributionLayer() {
    var mapPath;

    if (Edgar.mapdata.species) {

        var speciesId = Edgar.mapdata.species.id;
        var scenario = Edgar.mapdata.emissionScenario;
        var year = Edgar.mapdata.year;
        var bioData = 'csiro_mk3_5'; //what is this meant to be set to?
        var runs = 'run1.run1'; //what is this meant to be set to?

        //check box will be removed when it is working
        if($('#use_emission_and_year').is(':checked')){
            mapPath = speciesId+'/'+scenario+'.'+bioData+'.'+runs+'.'+year+'.asc';
        } else {
            mapPath = speciesId+'/1975.asc';
        }

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

        //    var sciNameCased = flattenScientificName(Edgar.mapdata.species.scientificName);

        distribution = new OpenLayers.Layer.WMS(
            "Climate Suitability",
            mapToolBaseUrl + 'wms_with_auto_determined_threshold.php', // path to our map script handler.

            // Params to send as part of request (note: keys will be auto-upcased)
            // I'm typing them in caps so I don't get confused.
            {
                MODE: 'map',
                MAP: 'edgar_master.map',
                DATA: mapPath,
                SPECIESID: Edgar.mapdata.species.id,
                REASPECT: "true",
                TRANSPARENT: 'true'
            },
            {
                // It's an overlay
                isBaseLayer: false,
                transitionEffect: 'resize',
                singleTile: true,
                ratio: 1.5,
            }
        );

        registerLayerProgress(distribution, "climate suitability");
        Edgar.map.addLayer(distribution);
    }
}

function addVettingLayer() {
    console.log('Adding vetting layer')
    var format = new OpenLayers.Format.GeoJSON({});

    var vettingStyleMap = new OpenLayers.StyleMap({
        'default': {
            'fillOpacity': 0.3,
            'strokeOpacity': 0.9,
            'fillColor': '${fill_color}',
            'strokeColor': '${stroke_color}',
            'fontColor': '${font_color}',
            'label': "${label}",
        },
        'select': {
            'fillOpacity': 1.0,
            'strokeOpacity': 1.0
        }
    });
    vettingLayer = new OpenLayers.Layer.Vector('Vetting Areas', {
        isBaseLayer: false,
        projection: geographic,
        strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})],
        protocol: new OpenLayers.Protocol.HTTP({
            url: (Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json"),
            format: new OpenLayers.Format.GeoJSON({})
        }),
        styleMap: vettingStyleMap
    });
    vettingLayerControl = new OpenLayers.Control.SelectFeature(vettingLayer, {hover: true});
    // NOTE: can't have two SelectFeature controls active at the same time...
    // SO.. TODO:
    //            convert code to use a single select feature control,
    //            and inject/remove layers from that select feature as necessary.
    Edgar.map.addLayer(vettingLayer);
    Edgar.map.addControl(vettingLayerControl);
    vettingLayerControl.activate();
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
                'fontSize': '13px'
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
                'pointRadius': "${point_radius}"
            },
            'dotgrid': {
                'pointRadius': "${point_radius}"
            },
            'squaregrid': {
                'label': "${label}",
                'fontOpacity': 1.0,
                'fillOpacity': 0.25,
                'strokeOpacity': 0.75
            }
        }
        occurrence_StyleMap.addUniqueValueRules("default", "occurrence_type", occurrence_render_styles);
        occurrence_StyleMap.addUniqueValueRules("select", "occurrence_type", occurrence_render_styles);

        var cluster_size_render_styles = {
            'large': {
//                'fontWeight': 'medium',
//                'fontSize': '12px',
                'fontWeight': 'bold',
                'fontSize': '13px'
            },
            'medium': {
                'fontWeight': 'medium',
                'fontSize': '12px'
            },
            'small': {
                'fontWeight': 'medium',
                'fontSize': '11px'
            }
        }
        occurrence_StyleMap.addUniqueValueRules("default", "cluster_size", cluster_size_render_styles);
        occurrence_StyleMap.addUniqueValueRules("select", "cluster_size", cluster_size_render_styles);

        // set the clustering to use for this occurrences layer
        cluster_strategy = "none";
        cluster_selector = document.getElementById("cluster");
        if (cluster_selector) {
            cluster_strategy = cluster_selector.options[cluster_selector.selectedIndex].value;
        } else {
            cluster_strategy = "dotgrid";
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
                    format: occurrences_format
                }),

                // the layer style
                styleMap: occurrence_StyleMap
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
                Edgar.map.addPopup(popup);
        }

        // what to do when a feature is no longed seected
        function onFeatureUnselect(evt) {
            feature = evt.feature;
            if (feature.popup) {
                popup.feature = null;
                Edgar.map.removePopup(feature.popup);
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
        Edgar.map.events.on({
            'zoomend': clearMapPopups
        });

        // Specify the selection control for the occurrences layer.
        //
        // Note: change hover to true to make it a on hover interaction (instead
        // of an on-click interaction)
        occurrence_select_control = new OpenLayers.Control.SelectFeature(
            occurrences, {hover: false}
        );

        registerLayerProgress(occurrences, "species occurrences");
        Edgar.map.addLayer(occurrences);

        Edgar.map.addControl(occurrence_select_control);
        occurrence_select_control.activate();
}

function flattenScientificName(name) {
    return $.trim(name).replace(/\./g, '').replace(/\s/g, '_');
}

function updateWindowHistory() {
    if(window.History.enabled) {
        window.History.replaceState(
            Edgar.mapdata.species,
            '',
            Edgar.baseUrl + 'species/map/' + Edgar.mapdata.species.id
        );
    }
}

$(function() {

    // The Map Object
    // ----------

    Edgar.map = new OpenLayers.Map('map', {
        projection: mercator,
        displayProjection: geographic,
        units: "m",
        maxResolution: 156543.0339,
        maxExtent: world_bounds,
        controls: [
            new OpenLayers.Control.ArgParser(),
            new OpenLayers.Control.Attribution(),
            new OpenLayers.Control.Navigation()
        ]

        // Setting the restrictedExtent will change the bounds
        // that pressing the 'world' icon zooms to.
        // User can manually zoom out past this point.
//            restrictedExtent: zoom_bounds

    });

    // I want to show the layer loading status on the layer-switcher, but
    // OpenLayers keeps remaking the dom elements in the switcher.
    // I'm attaching behaviour to the layer-added-to-map event that will
    // hook up all the loading indicators when layers are added.
    Edgar.map.events.register('addlayer', null, function(event) {

        // find the label DOM for a given layer --------------------------
        function layerLabelDom(layer) {
            var switcher = layer.map.getControlsByClass('OpenLayers.Control.LayerSwitcher')[0];
            var layerIndicator = $.grep(switcher.dataLayers, function(dl, index) {
                return (dl.layer === event.layer);
            });
            if (layerIndicator && layerIndicator.length > 0) {
                return $(layerIndicator[0].labelSpan);
            } else {
                return null;
            }
        } // -------------------------------------------------------------

        consolelog('registering layer ' + event.layer.name);

        // do stuff when the layer has started loading
        event.layer.events.register('loadstart', null, function(evt) {
            // find the layerswitcher
consolelog('start loading layer ' + evt.object.name + '...');
            var label = layerLabelDom(evt.object);
            if (label) {
                label.addClass('loading');
            } else {
consolelog('! no matching label for ' + evt.object.name + '!');
            }
            layersLoading.push(evt.object.name);
            loadingChanged();
        });

        // do stuff when the layer has finished loading
        event.layer.events.register('loadend', null, function(evt) {
consolelog('... done loading layer ' + evt.object.name);
            // find the layerswitcher
            var label = layerLabelDom(evt.object);
            if (label) {
                label.removeClass('loading');
            }
            layersLoading.splice( $.inArray(evt.object.name, layersLoading), 1 );
            loadingChanged();
        });
/*
        // do stuff when the layer has changed
        event.layer.events.register('visibilitychanged', null, function(evt) {
consolelog('layer visibility changed (' + event.layer.visibility + ') ' + event.layer.name);
            // find the layerswitcher
            var ls = map.getControlsByClass('OpenLayers.Control.LayerSwitcher')[0];
            var label = layerLabelDom(ls, event.layer);
            if (label) {
                label.addClass('notloading');
            }
            layersLoading.splice( $.inArray(event.layer.name, layersLoading), 1 );
            loadingChanged();
        });
*/


    });


    // not sure how to position controls while adding them in constructor.
    // instead I'm just adding the control here in the right place.
    Edgar.map.addControl(new OpenLayers.Control.PanZoom(), new OpenLayers.Pixel(5,60));


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
            'layers':'basic'
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
//    Edgar.map.addControl(new OpenLayers.Control.Permalink());
//    Edgar.map.addControl(new OpenLayers.Control.MousePosition());

    // Let the user change between layers
//    layerSwitcher = new OpenLayers.Control.ExtendedLayerSwitcher();
    layerSwitcher = new OpenLayers.Control.LayerSwitcher({
        div: $('#layerstool').get(0),
        roundedCorner: false,
        useLegendGraphics: true
    });
    layerSwitcher.ascending = false;

    Edgar.map.addControl(layerSwitcher);
//    layerSwitcher.maximizeControl();

    // Add our layers
    Edgar.map.addLayers([vmap0, osm, bing_aerial, bing_hybrid, bing_road, gsat, ghyb, gmap, gphy]);
    Edgar.map.setBaseLayer(gphy);

    // Zoom the map to the zoom_bounds specified earlier
    Edgar.map.zoomToExtent(zoom_bounds);

    addLegend();

});

function addLegend() {
}

