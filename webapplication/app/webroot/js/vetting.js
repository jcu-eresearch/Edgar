/*
JS for doing vetting
*/

var new_vet_vectors, wkt, new_vet_draw_polygon_control, new_vet_modify_polygon_control, new_vet_move_polyogn_control;
// buttons 100%..
// buttons text
// make button to drop in polygon..

function clearNewVettingMode(e) {
    console.log("Clearing current mode");

    new_vet_draw_polygon_control.deactivate();
    $('#newvet_draw_polygon_button').removeClass('button_down');

    new_vet_modify_polygon_control.deactivate();
    $('#newvet_modify_polygon_button').removeClass('button_down');

    new_vet_modify_polygon_control.deactivate();
    $('#newvet_modify_polygon_button').removeClass('button_down');
}

function handleDrawPolygonClick(e) {
    e.preventDefault();

    if ( $(e.srcElement).hasClass('button_down') ) {
        clearNewVettingMode();
    } else {
        clearNewVettingMode();
        $(e.srcElement).toggleClass('button_down');
        new_vet_draw_polygon_control.activate();
    }
    updateHint();
}

function handleModifyPolygonClick(e) {
    e.preventDefault();

    if ( $(e.srcElement).hasClass('button_down') ) {
        clearNewVettingMode();
    } else {
        clearNewVettingMode();
        $(e.srcElement).toggleClass('button_down');
        new_vet_modify_polygon_control.activate();
    }
    updateHint();
}

function handleClearPolygonClick(e) {
    e.preventDefault();

    clearNewVettingMode();

    new_vet_vectors.removeAllFeatures();

    updateHint();
}


// Sets the vetting hint to a random hint
function updateHint() {
    var drawPolygonHints = [
        ''
    ];
    var modifyPolygonHints = [
        '<p>Press <strong>Delete</strong> while over a vertice to delete it</p>'
    ];

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

function initVetting() {
    console.log("Starting to init vetting");

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

    new_vet_modify_polygon_control = new OpenLayers.Control.ModifyFeature(new_vet_vectors);

    // Specify the modify mode as re-shape
    new_vet_modify_polygon_control.mode = OpenLayers.Control.ModifyFeature.RESHAPE;


    // handle draw polygon press
    $('#newvet_draw_polygon_button').click( function(e) {
        handleDrawPolygonClick(e);
    });

    // handle modify polygon press
    $('#newvet_modify_polygon_button').click( function(e) {
        handleModifyPolygonClick(e);
    });

    // handle clear polygon press
    $('#newvet_clear_polygon_button').click( function(e) {
    });

    Edgar.map.addLayers([new_vet_vectors]);
    Edgar.map.addControl(new_vet_draw_polygon_control)
    Edgar.map.addControl(new_vet_modify_polygon_control)

    console.log("Finished init vetting");
}

function createNewVetting() {
    console.log("Processing create new vetting");
    // Get features from the vector layer (which are all known to be polygons)
    var new_vet_polygon_features = new_vet_vectors.features;

    if (new_vet_polygon_features.length === 0) {
        alert("No polygons provided");
        return false;
    }

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

$(function() {

    var vetpanel = $('#newvet');
    var vetform = $('#vetform');

    $('#vet_submit').click( function(e) {
        e.preventDefault();

        // Drop out of any editing mode.
        clearNewVettingMode();

        alert('Cylon says: Create New Vetting Pressed');

        // Submit the vetting
        createNewVetting();

    });

    initVetting();

});
