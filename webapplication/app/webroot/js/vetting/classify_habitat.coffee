###
# Code to control the classify a habitat interface
###

Edgar.vetting.classifyHabitat = {

    ###
    # Init the classify Habitat
    #
    # This is run once
    ###
    init: () ->
        consolelog "Starting to init the classify habitat interface"
        classifyHabitat = Edgar.vetting.classifyHabitat

        classifyHabitat.wkt = new OpenLayers.Format.WKT {
            'internalProjection': Edgar.map.baseLayer.projection
            'externalProjection': Edgar.util.projections.mercator
        }

        consolelog "Finished init-ing the classify habitat interface"

        null

        classifyHabitat.vectorLayerOptions = {
            ###
            # NOTE: Due to OpenLayers Bug.. can't do this.
            #   The modify feature control draws points onto the vector layer
            #   to show vertice drag points.. these drag points fail the geometryType
            #   test.
            # 'geometryType': OpenLayers.Geometry.Polygon
            ###
        }

        # Listen for button clicks
        classifyHabitat._addButtonHandlers()

        consolelog("Finished init new vetting")

        null

    ###
    # Code to add button click even handlers to DOM
    ###
    _addButtonHandlers: () ->

        ###
        handle draw polygon press
        ###
        $('#newvet_draw_polygon_button').click( (e) ->
            _handleDrawPolygonClick e
            null
        )

        ###
        handle add polygon press
        ###
        $('#newvet_add_polygon_button').click( (e) ->
            _handleAddPolygonClick e
            null
        )

        ###
        handle modify polygon press
        ###
        $('#newvet_modify_polygon_button').click( (e) ->
            _handleModifyPolygonClick e
            null
        )

        ###
        handle delete selected polygon press
        ###
        $('#newvet_delete_selected_polygon_button').click( (e) ->
            _handleDeleteSelectedPolygonClick e
            null
        )

        ###
        handle delete all polygon press
        ###
        $('#newvet_delete_all_polygons_button').click( (e) ->
            _handleDeleteAllPolygonClick e
            null
        )

        ###
        toggle the ui-state-hover class on hover events
        ###
        $('#newvet :button').hover(
            () ->
                classifyHabitat = Edgar.vetting.classifyHabitat
                $(classifyHabitat).addClass "ui-state-hover"
                null
            () ->
                classifyHabitat = Edgar.vetting.classifyHabitat
                $(classifyHabitat).removeClass "ui-state-hover"
                null
        )

        ###
        listen for newvet form submission
        ###
        vetpanel = $('#newvet')
        vetform = $('#vetform')

        # Add click handler to vet_submit form
        $('#vet_submit').click( (e) ->
            e.preventDefault()

            ###
            # validate the form
            # and, if valid, submit its contents
            ###
            # if the form was valid...
            if _validateNewVetForm()
                # submit the vetting
                _createNewVetting()
            else
                false
        )

    engage: () ->
        consolelog "Starting engageClassifyHabitatInterface"

        this._addVectorLayer()
        this._addDrawControl()
        this._addModifyControl()

        consolelog "Finished engageClassifyHabitatInterface"

        null

    _addVectorLayer: () ->
        classifyHabitat = Edgar.vetting.classifyHabitat

        ###
        # Define a vector layer to hold a user's area classification
        ###
        classifyHabitat.vectorLayer = new OpenLayers.Layer.Vector "New Area Classification", classifyHabitat.vectorLayerOptions
        Edgar.map.addLayers  [classifyHabitat.vectorLayer]

    _removeVectorLayer: () ->
        # TODO
        null

    _addDrawControl: () ->
        classifyHabitat = Edgar.vetting.classifyHabitat
        classifyHabitat.drawControl = new OpenLayers.Control.DrawFeature(
            classifyHabitat.vectorLayer
            OpenLayers.Handler.Polygon
        )
        Edgar.map.addControl classifyHabitat.drawControl

        null

    _removeDrawControl: () ->
        # TODO
        null

    _addModifyControl: () ->
        classifyHabitat = Edgar.vetting.classifyHabitat

        ###
        # Create a Modify Feature control
        # Allow users to:
        #    - Reshape
        #    - Drag
        ###
        classifyHabitat.modifyControl = new OpenLayers.Control.ModifyFeature(
            classifyHabitat.vectorLayer
            {
                mode: ( OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG )
                beforeSelectFeature: (feature) ->
                    $('#newvet_delete_selected_polygon_button').attr("disabled", false).removeClass("ui-state-disabled")
                    null
                unselectFeature: (feature) ->
                    $('#newvet_delete_selected_polygon_button').attr("disabled", true).addClass("ui-state-disabled")
                    null
            }
        )

        null

    _removeModifyControl: () ->
        # TODO
        null


    _clearNewVettingMode: (e) ->
        classifyHabitat = Edgar.vetting.classifyHabitat
        consolelog "Clearing classify habitat mode of operation"

        removeModifyFeatureHandlesAndVertices()

        # Deactivate draw polygon control
        classifyHabitat.drawControl.deactivate()
        $('#newvet_draw_polygon_button').removeClass 'ui-state-active'

        # Deactivate modify polygon control
        classifyHabitat.modifyControl.deactivate()
        $('#newvet_modify_polygon_button').removeClass 'ui-state-active'

        _updateNewVetHint()

        null

    _activateDrawPolygonMode: () ->
        _clearNewVettingMode()
        $('#newvet_draw_polygon_button').addClass 'ui-state-active'
        new_vet_draw_polygon_control.activate()
        _updateNewVetHint()

        null

    _activateModifyPolygonMode: () ->
        _clearNewVettingMode()
        $('#newvet_modify_polygon_button').addClass 'ui-state-active'

        # Specify the modify mode as reshape and drag 
        classifyHabitat.modifyControl.mode = OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG
        classifyHabitat.modifyControl.activate()
        _updateNewVetHint()

    _handleToggleButtonClick: (e, onActivatingButton, onDeactivatingButton) ->
        e.preventDefault()
        if $(e.srcElement).hasClass 'ui-state-active'
            onDeactivatingButton()
        else
            onActivatingButton()

        null

    _handleDrawPolygonClick: (e) ->
        _handleToggleButtonClick(e, _activateDrawPolygonMode, _clearNewVettingMode)

        null

    _handleModifyPolygonClick: (e) ->
        _handleToggleButtonClick(e, _activateModifyPolygonMode, _clearNewVettingMode)

        null

    _handleAddPolygonClick: (e) ->
        classifyHabitat = Edgar.vetting.classifyHabitat

        e.preventDefault()

        _clearNewVettingMode()

        # Determine position to add polygon..
        # then add it.
        # Get the center of the map.
        centerOfMap = Edgar.map.getCenter
        mapBounds   = Edgar.map.getExtent
        mapHeight   = ( mapBounds.top   - mapBounds.bottom )
        mapWidth    = ( mapBounds.right - mapBounds.left )

        calcDimension = null
        if (mapHeight > mapWidth)
            calcDimension = mapHeight
        else
            calcDimension = mapWidth

        majorFraction = calcDimension / 10
        minorFraction = calcDimension / 14

        points = [
            new OpenLayers.Geometry.Point(centerOfMap.lon - minorFraction, centerOfMap.lat - majorFraction)
            new OpenLayers.Geometry.Point(centerOfMap.lon - majorFraction, centerOfMap.lat)
            new OpenLayers.Geometry.Point(centerOfMap.lon, centerOfMap.lat + minorFraction)
            new OpenLayers.Geometry.Point(centerOfMap.lon + majorFraction, centerOfMap.lat)
            new OpenLayers.Geometry.Point(centerOfMap.lon + minorFraction, centerOfMap.lat - majorFraction)
        ]

        ring = new OpenLayers.Geometry.LinearRing points
        polygon = new OpenLayers.Geometry.Polygon [ring]

        # create some attributes for the feature
        attributes = {}

        feature = new OpenLayers.Feature.Vector polygon, attributes
        classifyHabitat.vectorLayer.addFeatures [feature]

        _activateModifyPolygonMode()

        null

    _removeModifyFeatureHandlesAndVertices: () ->
        classifyHabitat = Edgar.vetting.classifyHabitat
        classifyHabitat.vectorLayer.addFeatures [feature]

        # Delete any modify control vertices.
        classifyHabitat.vectorLayer.removeFeatures classifyHabitat.modifyControl.virtualVertices, { silent: true }
        classifyHabitat.vectorLayer.removeFeatures classifyHabitat.modifyControl.vertices, { silent: true }
        # Delete the radius handle.
        classifyHabitat.vectorLayer.removeFeatures classifyHabitat.modifyControl.radiusHandle, { silent: true }
        # Delete the drag handle.
        classifyHabitat.vectorLayer.removeFeatures classifyHabitat.modifyControl.dragHandle, { silent: true }

        null

    _handleDeleteSelectedPolygonClick: (e) ->
        e.preventDefault()
        classifyHabitat = Edgar.vetting.classifyHabitat
        currentFeature =  classifyHabitat.modifyControl.feature

        if(currentFeature)
            # Unselect the feature.
            classifyHabitat.modifyControl.unselectFeature(currentFeature)
            _removeModifyFeatureHandlesAndVertices()
            # Delete the selected feature
            classifyHabitat.vectorLayer.removeFeatures(currentFeature)

            # If all Features are now deleted,
            # clear the vetting mode (get out of modify mode)
            if classifyHabitat.vectorLayer.features.length == 0
                _clearNewVettingMode()

        null


    _handleDeleteAllPolygonClick: (e) ->
        e.preventDefault()
        classifyHabitat = Edgar.vetting.classifyHabitat

        _clearNewVettingMode()

        classifyHabitat.vectorLayer.removeAllFeatures()

        _updateNewVetHint()

        null


    # Sets the vetting hint to a random hint
    _updateNewVetHint: () ->
        drawPolygonHints = [
            ''
        ]

        modifyPolygonHints = [
            '<p>Press <strong>Delete</strong> while over a corner to delete it</p>'
        ]

        movePolygonHints = [
            ''
        ]

        # Modify feature is active
        if new_vet_modify_polygon_control.active
            hint = modifyPolygonHints[Math.floor(Math.random()*modifyPolygonHints.length)]
            $('#vethint').html hint
        else if new_vet_draw_polygon_control
            hint = drawPolygonHints[Math.floor(Math.random()*drawPolygonHints.length)]
            $('#vethint').html hint
        else
            $('#vethint').html ''

        null


    _createNewVetting: () ->
        consolelog "Processing create new vetting"

        classifyHabitat = Edgar.vetting.classifyHabitat

        # Get features from the vector layer (which are all known to be polygons)
        newVetPolygonFeatures = classifyHabitat.features
        # Now convert our array of features into an array of geometries.
        newVetPolygonGeoms = []
        newVetPolygonGeoms.push(feature.geometry) for feature in newVetPolygonFeatures

        # Create a MultiPolygon from our polygons.
        newVetPolygon = new OpenLayers.Geometry.MultiPolygon newVetPolygonGeoms
        consolelog "WKT logs:"
        consolelog "polygon", newVetPolygon

        # Get WKT (well known text) for the multipolygon
        layerWKTString = classifyHabitat.wkt.extractGeometry(newVetPolygon)
        # At this point, we have our WKT
        consolelog "layer string", layerWKTString

        speciesId = Edgar.mapdata.species.id
        newVetData = {
            area:           layerWKTString
            species_id:     speciesId
            comment:        $("#vetcomment").val()
            classification: $("#vetclassification").val()
        }

        # At this point, we have filled out our submit form
        consolelog "Post Data", newVetData
        vetDataAsJSONString = JSON.stringify newVetData
        consolelog "Post Data as JSON", vetDataAsJSONString
        url = ( Edgar.baseUrl + "species/insert_vetting/" + species_id + ".json" )

        # Send the new vet to the back-end
        $.post(
            url
            vet_data_as_json_str
            (data, text_status, jqXHR) ->
                consolelog "New Vet Response", data, text_status, jqXHR
                alert "New Vet Response: " + data
            'json'
        )

        true

    # Returns true if valid
    # Returns false else
    _validateNewVetForm: () ->
        classifyHabitat = Edgar.vetting.classifyHabitat

        # Get features from the vector layer (which are all known to be polygons)
        newVetPolygonFeatures = classifyHabitat.features

        if (Edgar.mapdata.species == null)
            alert "No species selected"
            false
        else if (new_vet_polygon_features.length == 0)
            alert "No polygons provided"
            $('#newvet_add_polygon_button').effect("highlight", {}, 5000)
            false
        else if ($('#vetclassification').val() == '')
            alert "No classification provided"
            $('#vetclassification').effect("highlight", {}, 5000)
            false
        else
            true
}
