###
Code to control the classify a habitat interface
###

Edgar.vetting.classifyHabitat = {

    ###
    Init the classify Habitat

    This is run once
    ###
    init: () ->
        consolelog "Starting to init the classify habitat interface"

        Edgar.vetting.classifyHabitat.wkt = new OpenLayers.Format.WKT {
            'internalProjection': Edgar.map.baseLayer.projection,
            'externalProjection': Edgar.util.projections.mercator
        }

        consolelog "Finished init-ing the classify habitat interface"

        null

        Edgar.vetting.classifyHabitat.vectorLayerOptions = {
            ###
            NOTE: Due to OpenLayers Bug.. can't do this.
              The modify feature control draws points onto the vector layer
              to show vertice drag points.. these drag points fail the geometryType
              test.
            'geometryType': OpenLayers.Geometry.Polygon
            ###
        }

        # Listen for button clicks
        Edgar.vetting.classifyHabitat._addButtonHandlers()

        consolelog("Finished init new vetting");

        null

    ###
        Code to add button click even handlers to DOM
    ###
    _addButtonHandlers: () ->
        ###
        handle draw polygon press
        ###
        $('#newvet_draw_polygon_button').click( (e) ->
            handleDrawPolygonClick e
            null
        )

        ###
        handle add polygon press
        ###
        $('#newvet_add_polygon_button').click( (e) ->
            handleAddPolygonClick e
            null
        );

        ###
        handle modify polygon press
        ###
        $('#newvet_modify_polygon_button').click( (e) ->
            handleModifyPolygonClick e
            null
        );

        ###
        handle delete selected polygon press
        ###
        $('#newvet_delete_selected_polygon_button').click( (e) ->
            handleDeleteSelectedPolygonClick e
            null
        );

        ###
        handle delete all polygon press
        ###
        $('#newvet_delete_all_polygons_button').click( (e) ->
            handleDeleteAllPolygonClick e
            null
        );

        ###
        toggle the ui-state-hover class on hover events
        ###
        $('#newvet :button').hover(
            () ->
                $(Edgar.vetting.classifyHabitat).addClass "ui-state-hover"
                null
            ,
            () ->
                $(Edgar.vetting.classifyHabitat).removeClass "ui-state-hover"
                null
        )

        ###
        listen for newvet form submission
        ###
        vetpanel = $('#newvet');
        vetform = $('#vetform');

        # Add click handler to vet_submit form
        $('#vet_submit').click( (e) ->
            e.preventDefault()

            ###
            validate the form
            and, if valid, submit its contents
            ###
            # if the form was valid...
            if(validateNewVetForm())
                # submit the vetting
                createNewVetting()
            # else do nothing

            null
        );

    engage: () ->
        consolelog "Starting engageClassifyHabitatInterface"
        ###
        Define a vector layer to hold a user's area classification
        ###
        Edgar.vetting.classifyHabitat.vectorLayer = new OpenLayers.Layer.Vector "New Area Classification", Edgar.vetting.classifyHabitat.classifyHabitat.vectorLayerOptions

        ###
        Create a Draw control to let users draw an area (polygon)
        ###
        Edgar.vetting.classifyHabitat.drawControl = new OpenLayers.Control.DrawFeature(
            Edgar.vetting.classifyHabitat.vectorLayer,
            OpenLayers.Handler.Polygon
        )

        ###
        Create a Modify Feature control
        Allow users to:
            - Reshape
            - Drag
        ###
        Edgar.vetting.classifyHabitat.modifyControl = new OpenLayers.Control.ModifyFeature(Edgar.vetting.classifyHabitat.vectorLayer, {
            mode: OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG,
            beforeSelectFeature: (feature) -> 
                $('#newvet_delete_selected_polygon_button').attr("disabled", false).removeClass("ui-state-disabled")
                null
            ,
            unselectFeature: (feature) ->
                $('#newvet_delete_selected_polygon_button').attr("disabled", true).addClass("ui-state-disabled")
                null
        });

        Edgar.map.addLayers     [Edgar.vetting.classifyHabitat.vectorLayer]
        Edgar.map.addControl    Edgar.vetting.classifyHabitat.drawControl
        Edgar.map.addControl    Edgar.vetting.classifyHabitat.modifyControl

        consolelog "Finished engageClassifyHabitatInterface"

        null

    clearNewVettingMode: (e) ->
        consolelog "Clearing classify habitat mode of operation"

        removeModifyFeatureHandlesAndVertices()

        # Deactivate draw polygon control
        Edgar.vetting.classifyHabitat.drawControl.deactivate()
        $('#newvet_draw_polygon_button').removeClass 'ui-state-active'

        # Deactivate modify polygon control
        Edgar.vetting.classifyHabitat.modifyControl.deactivate()
        $('#newvet_modify_polygon_button').removeClass 'ui-state-active'

        updateNewVetHint()

    activateDrawPolygonMode: () ->
        clearNewVettingMode()
        $('#newvet_draw_polygon_button').addClass 'ui-state-active'
        new_vet_draw_polygon_control.activate()
        updateNewVetHint()

    activateModifyPolygonMode: () ->
        clearNewVettingMode()
        $('#newvet_modify_polygon_button').addClass 'ui-state-active'

        # Specify the modify mode as reshape and drag 
        Edgar.vetting.classifyHabitat.modifyControl.mode = OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG
        Edgar.vetting.classifyHabitat.modifyControl.activate()
        updateNewVetHint()

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
        classify_habitat_vectors.addFeatures([feature]);

        activateModifyPolygonMode();
    }

    function removeModifyFeatureHandlesAndVertices() {
        // Delete any modify control vertices.
        classify_habitat_vectors.removeFeatures(new_vet_modify_polygon_control.virtualVertices, { silent: true });
        classify_habitat_vectors.removeFeatures(new_vet_modify_polygon_control.vertices, { silent: true });
        // Delete the radius handle.
        classify_habitat_vectors.removeFeatures(new_vet_modify_polygon_control.radiusHandle, { silent: true });
        // Delete the drag handle.
        classify_habitat_vectors.removeFeatures(new_vet_modify_polygon_control.dragHandle, { silent: true });
    }

    function handleDeleteSelectedPolygonClick(e) {
        e.preventDefault();
        currentFeature = new_vet_modify_polygon_control.feature;
        if(currentFeature) {
            // Unselect the feature.
            new_vet_modify_polygon_control.unselectFeature(currentFeature);
            removeModifyFeatureHandlesAndVertices();
            // Delete the selected feature
            classify_habitat_vectors.removeFeatures(currentFeature);

            // If all Features are now deleted,
            // clear the vetting mode (get out of modify mode)
            if (classify_habitat_vectors.features.length === 0) {
                clearNewVettingMode();
            }
        }

    }

    function handleDeleteAllPolygonClick(e) {
        e.preventDefault();

        clearNewVettingMode();

        classify_habitat_vectors.removeAllFeatures();

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
        var new_vet_polygon_features = classify_habitat_vectors.features;
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
        var new_vet_polygon_features = classify_habitat_vectors.features;

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
}
