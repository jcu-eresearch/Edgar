/*
JS for browsing existing vettings,
and for adding and modifying vettings.
*/

// ************************** New Vetting Code *******************************
var new_vet_vectors, wkt, new_vet_draw_polygon_control, new_vet_modify_polygon_control;

function initNewVettingInterface() {
    console.log("Starting to init new vetting");

    // DecLat, DecLng 
    var geographic_proj = new OpenLayers.Projection("EPSG:4326");

    var wkt_in_options = {
         'internalProjection': Edgar.map.baseLayer.projection,
         'externalProjection': geographic_proj
    };
    wkt = new OpenLayers.Format.WKT(wkt_in_options);


// NOTE: Due to OpenLayers Bug.. can't do this.
//       The modify feature control draws points onto the vector layer
//       to show vertice drag points.. these drag points fail the geometryType
//       test.
    var new_vet_vectors_options = {
//       'geometryType': OpenLayers.Geometry.Polygon
    };
    new_vet_vectors = new OpenLayers.Layer.Vector("New Vetting Layer", new_vet_vectors_options);

    new_vet_draw_polygon_control = new OpenLayers.Control.DrawFeature(
        new_vet_vectors,
        OpenLayers.Handler.Polygon
    );

    new_vet_modify_polygon_control = new OpenLayers.Control.ModifyFeature(new_vet_vectors, {
        mode: OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG,
        beforeSelectFeature: function(feature) { 
            $('#newvet_delete_selected_polygon_button').attr("disabled", false).removeClass("ui-state-disabled");
        },
        unselectFeature: function(feature) { 
            $('#newvet_delete_selected_polygon_button').attr("disabled", true).addClass("ui-state-disabled");
        }
    });

    // handle draw polygon press
    $('#newvet_draw_polygon_button').click( function(e) {
        handleDrawPolygonClick(e);
    });

    // handle add polygon press
    $('#newvet_add_polygon_button').click( function(e) {
        handleAddPolygonClick(e);
    });

    // handle modify polygon press
    $('#newvet_modify_polygon_button').click( function(e) {
        handleModifyPolygonClick(e);
    });

    // handle delete selected polygon press
    $('#newvet_delete_selected_polygon_button').click( function(e) {
        handleDeleteSelectedPolygonClick(e);
    });

    // handle delete all polygon press
    $('#newvet_delete_all_polygons_button').click( function(e) {
        handleDeleteAllPolygonClick(e);
    });

    // toggle the ui-state-hover class on hover events
    $('#newvet :button').hover(
        function(){ 
            $(this).addClass("ui-state-hover"); 
        },
        function(){ 
            $(this).removeClass("ui-state-hover"); 
        }
    )

    var vetpanel = $('#newvet');
    var vetform = $('#vetform');

    // Add click handler to vet_submit form
    $('#vet_submit').click( function(e) {
        e.preventDefault();

        // Drop out of any editing mode.
        clearNewVettingMode();

        // if the form was vetting
        // else
        if(validateNewVetForm()) {
            // Submit the vetting
            createNewVetting();
        }

    });


    Edgar.map.addLayers([new_vet_vectors]);
    Edgar.map.addControl(new_vet_draw_polygon_control)
    Edgar.map.addControl(new_vet_modify_polygon_control)

    console.log("Finished init new vetting");
}

function clearNewVettingMode(e) {
    console.log("Clearing current mode");

    removeModifyFeatureHandlesAndVertices();

    // Deactivate draw polygon control
    new_vet_draw_polygon_control.deactivate();
    $('#newvet_draw_polygon_button').removeClass('ui-state-active');

    // Deactivate modify polygon control
    new_vet_modify_polygon_control.deactivate();
    $('#newvet_modify_polygon_button').removeClass('ui-state-active');

    updateNewVetHint();
}

function activateDrawPolygonMode() {
    clearNewVettingMode();
    $('#newvet_draw_polygon_button').addClass('ui-state-active');
    new_vet_draw_polygon_control.activate();
    updateNewVetHint();
}

function activateModifyPolygonMode() {
    clearNewVettingMode();
    $('#newvet_modify_polygon_button').addClass('ui-state-active');

    // Specify the modify mode as reshape and drag 
    new_vet_modify_polygon_control.mode = OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG;
    new_vet_modify_polygon_control.activate();
    updateNewVetHint();
}

function handleToggleButtonClick(e, onActivatingButton, onDeactivatingButton) {
    e.preventDefault();
    if ( $(e.srcElement).hasClass('ui-state-active') ) {
        onDeactivatingButton();
    } else {
        onActivatingButton();
    }
}

function handleDrawPolygonClick(e) {
    handleToggleButtonClick(e, activateDrawPolygonMode, clearNewVettingMode);
}

function handleModifyPolygonClick(e) {
    handleToggleButtonClick(e, activateModifyPolygonMode, clearNewVettingMode);
}

function handleAddPolygonClick(e) {
    e.preventDefault();

    clearNewVettingMode();

    // Determine position to add polygon..
    // then add it.
    // Get the center of the map.
    var centerOfMap = Edgar.map.getCenter();
    var mapBounds   = Edgar.map.getExtent();
    var mapHeight   = mapBounds.top   - mapBounds.bottom;
    var mapWidth    = mapBounds.right - mapBounds.left;

    var calcDimension = null;
    if (mapHeight > mapWidth) {
        calcDimension = mapHeight;
    } else {
        calcDimension = mapWidth;
    }

    var largerFraction = calcDimension / 10;
    var minorFraction = calcDimension / 14;

    var points = [
        new OpenLayers.Geometry.Point(centerOfMap.lon - minorFraction, centerOfMap.lat - largerFraction),
        new OpenLayers.Geometry.Point(centerOfMap.lon - largerFraction, centerOfMap.lat),
        new OpenLayers.Geometry.Point(centerOfMap.lon, centerOfMap.lat + minorFraction),
        new OpenLayers.Geometry.Point(centerOfMap.lon + largerFraction, centerOfMap.lat),
        new OpenLayers.Geometry.Point(centerOfMap.lon + minorFraction, centerOfMap.lat - largerFraction)
    ];

    var ring = new OpenLayers.Geometry.LinearRing(points);
    var polygon = new OpenLayers.Geometry.Polygon([ring]);

    // create some attributes for the feature
    var attributes = {};

    var feature = new OpenLayers.Feature.Vector(polygon, attributes);
    new_vet_vectors.addFeatures([feature]);

    activateModifyPolygonMode();
}

function removeModifyFeatureHandlesAndVertices() {
    // Delete any modify control vertices.
    new_vet_vectors.removeFeatures(new_vet_modify_polygon_control.virtualVertices, { silent: true });
    new_vet_vectors.removeFeatures(new_vet_modify_polygon_control.vertices, { silent: true });
    // Delete the radius handle.
    new_vet_vectors.removeFeatures(new_vet_modify_polygon_control.radiusHandle, { silent: true });
    // Delete the drag handle.
    new_vet_vectors.removeFeatures(new_vet_modify_polygon_control.dragHandle, { silent: true });
}

function handleDeleteSelectedPolygonClick(e) {
    e.preventDefault();
    currentFeature = new_vet_modify_polygon_control.feature;
    if(currentFeature) {
        // Unselect the feature.
        new_vet_modify_polygon_control.unselectFeature(currentFeature);
        removeModifyFeatureHandlesAndVertices();
        // Delete the selected feature
        new_vet_vectors.removeFeatures(currentFeature);

        // If all Features are now deleted,
        // clear the vetting mode (get out of modify mode)
        if (new_vet_vectors.features.length === 0) {
            clearNewVettingMode();
        }
    }

}

function handleDeleteAllPolygonClick(e) {
    e.preventDefault();

    clearNewVettingMode();

    new_vet_vectors.removeAllFeatures();

    updateNewVetHint();
}


// Sets the vetting hint to a random hint
function updateNewVetHint() {
    var drawPolygonHints = [
        ''
    ];

    var modifyPolygonHints = [
        '<p>Press <strong>Delete</strong> while over a corner to delete it</p>'
    ];

    var movePolygonHints = [
        ''
    ];

    // Modify feature is active
    if (new_vet_modify_polygon_control.active) {
        var hint = modifyPolygonHints[Math.floor(Math.random()*modifyPolygonHints.length)]
        $('#vethint').html(hint);
    } else if (new_vet_draw_polygon_control) {
        var hint = drawPolygonHints[Math.floor(Math.random()*drawPolygonHints.length)]
        $('#vethint').html(hint);
    } else {
        $('#vethint').html('');
    }
}


function createNewVetting() {
    console.log("Processing create new vetting");

    // Get features from the vector layer (which are all known to be polygons)
    var new_vet_polygon_features = new_vet_vectors.features;
    // Now convert our array of features into an array of geometries.
    var new_vet_polygon_geoms = [];
    for (var i = 0; i < new_vet_polygon_features.length; i++) {
        var i_feature = new_vet_polygon_features[i];
        var i_geom = i_feature.geometry;
        new_vet_polygon_geoms.push(i_geom);
    }

    // Create a MultiPolygon from our polygons.
    var new_vet_multipolygon = new OpenLayers.Geometry.MultiPolygon(new_vet_polygon_geoms);
    console.log("WKT");
    console.log(new_vet_multipolygon);

    // Get WKT (well known text) for the multipolygon
    var layer_wkt_str = wkt.extractGeometry(new_vet_multipolygon);
    // At this point, we have our WKT
    console.log(layer_wkt_str);

    var species_id = Edgar.mapdata.species.id;
    var new_vet_data = {
        area: layer_wkt_str,
        species_id: species_id,
        comment: $("#vetcomment").val(),
        classification: $("#vetclassification").val()
    };

    // At this point, we have filled out our submit form
    console.log("Post Data:");
    console.log(new_vet_data);
    var vet_data_as_json_str = JSON.stringify(new_vet_data);
    console.log(vet_data_as_json_str);
    var url = Edgar.baseUrl + "species/insert_vetting/" + species_id + ".json";

    // Send the new vet to the back-end
    $.post(url, vet_data_as_json_str, function(data, text_status, jqXHR) {
        console.log("New Vet Response", data, text_status, jqXHR);
        alert("New Vet Response: " + data);
    }, 'json');

    return true;
}

// Returns true if valid
// Returns false else
function validateNewVetForm() {
    // Get features from the vector layer (which are all known to be polygons)
    var new_vet_polygon_features = new_vet_vectors.features;

    if(Edgar.mapdata.species === null) {
        alert("No species selected");
        return false;
    }

    if (new_vet_polygon_features.length === 0) {
        alert("No polygons provided");
        $('#newvet_add_polygon_button').effect("highlight", {}, 5000);
        return false;
    }

    if ($('#vetclassification').val() === '') {
        alert("No classification provided");
        $('#vetclassification').effect("highlight", {}, 5000);
        return false;
    }

    return true;
}


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

$(function() {
    initExistingVettingInterface();
    initNewVettingInterface();
});
