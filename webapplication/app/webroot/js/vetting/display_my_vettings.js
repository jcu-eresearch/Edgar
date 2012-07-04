/*
JS for browsing existing vettings
*/

// ************************** Existing Vettings Code *******************************
var vettingLayer, vettingLayerControl;

function initExistingVettingInterface() {
    console.log("Starting to init existing vetting");

    var geographic_proj = new OpenLayers.Projection("EPSG:4326");
    var format = new OpenLayers.Format.GeoJSON({});

    var vettingStyleMap = new OpenLayers.StyleMap({
        'default': {
            'fillOpacity': 0.3,
            'strokeOpacity': 0.9,
            'fillColor': '${fill_color}',
            'strokeColor': '${stroke_color}',
            'fontColor': '${font_color}',
            'label': '${classification}',
        },
        'select': {
            'fillOpacity': 1.0,
            'strokeOpacity': 1.0
        }
    });
    vettingLayer = new OpenLayers.Layer.Vector('Vetting Areas', {
        isBaseLayer: false,
        projection: geographic_proj,
        strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})],
        protocol: new OpenLayers.Protocol.HTTP({
            url: (Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json"),
            format: new OpenLayers.Format.GeoJSON({}),
        }),
        styleMap: vettingStyleMap
    });
    vettingLayerControl = new OpenLayers.Control.SelectFeature(vettingLayer, {hover: true});
    vettingLayer.events.register('loadend', null, vettingLayerUpdated);

    // NOTE: can't have two SelectFeature controls active at the same time...
    // SO.. TODO:
    //            convert code to use a single select feature control,
    //            and inject/remove layers from that select feature as necessary.
    Edgar.map.addLayer(vettingLayer);
    Edgar.map.addControl(vettingLayerControl);
    vettingLayerControl.activate();

    console.log("Finished init existing vetting");
}

function vettingLayerUpdated() {
    // Clear the list of existing features
    var other_peoples_vettings_list = $('#other_peoples_vettings_list');
    other_peoples_vettings_list.empty();

    // Process Vetting Layer Features.
    var vetting_features = vettingLayer.features;
    console.log(vetting_features);
    for (var feature_index in vetting_features) {
        var feature = vetting_features[feature_index];
        var feature_data = feature.data;
        console.log(feature);
        console.log(feature_data);
        var classification = feature_data['classification'];
        var comment = feature_data['comment'];
        var li_vetting = $('<li class="ui-state-default"><span class="classification">' + classification + '</span><span class="comment">' + comment + '</span></li>');
        li_vetting.data('feature', feature);
        li_vetting.hover(
            function(){ 
                // Select the feature
                var feature = $(this).data('feature');
                vettingLayerControl.select(feature);
                console.log(feature);
                $(this).addClass("ui-state-hover"); 
            },
            function(){ 
                // Unselect the feature
                vettingLayerControl.unselectAll();
                $(this).removeClass("ui-state-hover"); 
            }
        )
        other_peoples_vettings_list.append(li_vetting);
    }

}

function destroyExistingVettingInterface() {
    if(vettingLayer !== undefined) {
        console.log('Removing vetting layer');
        Edgar.map.removeLayer(vettingLayer);
        vettingLayerControl.unselectAll();
        vettingLayerControl.deactivate();
        Edgar.map.removeControl(vettingLayerControl);
        vettingLayer = undefined;
        vettingLayerControl = undefined;
        console.log('Removed vetting layer');
    }
}
