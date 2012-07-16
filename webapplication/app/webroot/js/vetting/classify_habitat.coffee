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

        @wkt = new OpenLayers.Format.WKT {
            'internalProjection': Edgar.map.baseLayer.projection
            'externalProjection': Edgar.util.projections.geographic
        }

        @vectorLayerOptions = {
            ###
            # NOTE: Due to OpenLayers Bug.. can't do this.
            #   The modify feature control draws points onto the vector layer
            #   to show vertice drag points.. these drag points fail the geometryType
            #   test.
            # 'geometryType': OpenLayers.Geometry.Polygon
            ###
        }

        # Listen for button clicks
        this._addButtonHandlers()

        consolelog "Finished init-ing the classify habitat interface"

        null

    _confirmModeChangeOkayViaDialog: (newMode) ->
        myDialog = $( "#discard-area-classifcation-confirm" ).dialog(
            resizable: false
            width:    400
            modal:     true
            buttons: {
                "Discard area classification": () =>
                    $( this ).dialog( "close" )
                    this._removeAllFeatures()
                    $(Edgar.map).trigger 'changemode', $( this ).data('newMode')
                Cancel: () =>
                    $( this ).dialog( "close" )
            }
        )
        myDialog.data 'newMode', newMode

    isChangeModeOkay: (newMode) ->
        if ( 'vectorLayer' of this ) and ( @vectorLayer.features.length > 0 )
            this._confirmModeChangeOkayViaDialog(newMode)
            false
        else
            true

    ###
    # Code to add button click even handlers to DOM
    ###
    _addButtonHandlers: () ->

        ###
        handle draw polygon press
        ###
        $('#newvet_draw_polygon_button').click( (e) =>
            this._handleDrawPolygonClick e
            null
        )

        ###
        handle add polygon press
        ###
        $('#newvet_add_polygon_button').click( (e) =>
            this._handleAddPolygonClick e
            null
        )

        ###
        handle modify polygon press
        ###
        $('#newvet_modify_polygon_button').click( (e) =>
            this._handleModifyPolygonClick e
            null
        )

        ###
        handle delete selected polygon press
        ###
        $('#newvet_delete_selected_polygon_button').click( (e) =>
            this._handleDeleteSelectedPolygonClick e
            null
        )

        ###
        handle delete all polygon press
        ###
        $('#newvet_delete_all_polygons_button').click( (e) =>
            this._handleDeleteAllPolygonClick e
            null
        )

        ###
        # toggle the ui-state-hover class on hover events
        ###
        $('#newvet :button').hover(
            () ->
                $(this).addClass "ui-state-hover"
                null
            () ->
                $(this).removeClass "ui-state-hover"
                null
        )

        ###
        listen for newvet form submission
        ###
        vetpanel = $('#newvet')
        vetform = $('#vetform')

        # Add click handler to vet_submit form
        $('#vet_submit').click( (e) =>
            e.preventDefault()

            ###
            # validate the form
            # and, if valid, submit its contents
            ###
            # if the form was valid...
            if this._validateNewVetForm()
                # submit the vetting
                this._createNewVetting()
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

    disengage: () ->
        consolelog "Starting disengageClassifyHabitatInterface"

        this._clearNewVettingMode()

        this._removeDrawControl()
        this._removeModifyControl()
        this._removeVectorLayer()

        consolelog "Finished disengageClassifyHabitatInterface"

    _addVectorLayer: () ->
        ###
        # Define a vector layer to hold a user's area classification
        ###
        @vectorLayer = new OpenLayers.Layer.Vector "New Area Classification", @vectorLayerOptions
        Edgar.map.addLayers  [@vectorLayer]

    _removeVectorLayer: () ->
        Edgar.map.removeLayer(@vectorLayer)
        delete @vectorLayer

        null

    _addDrawControl: () ->
        @drawControl = new OpenLayers.Control.DrawFeature(
            @vectorLayer
            OpenLayers.Handler.Polygon
        )
        Edgar.map.addControl @drawControl

        null

    ###
    # Removes the draw control
    # Note: Assumes _clearNewVettingMode was already run
    ###
    _removeDrawControl: () ->
        @drawControl.map.removeControl @modifyControl
        delete @drawControl

        null

    _addModifyControl: () ->

        ###
        # Create a Modify Feature control
        # Allow users to:
        #    - Reshape
        #    - Drag
        ###
        @modifyControl = new OpenLayers.Control.ModifyFeature(
            @vectorLayer
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
        Edgar.map.addControl @modifyControl

        null

    ###
    # Removes the modify control
    # Note: Assumes _clearNewVettingMode was already run
    ###
    _removeModifyControl: () ->
        @modifyControl.map.removeControl @modifyControl
        delete @modifyControl

        null

    _clearNewVettingMode: (e) ->
        consolelog "Clearing classify habitat mode of operation"

        this._removeModifyFeatureHandlesAndVertices()

        # Deactivate draw polygon control
        @drawControl.deactivate()
        $('#newvet_draw_polygon_button').removeClass 'ui-state-active'

        # Deactivate modify polygon control
        @modifyControl.deactivate()
        $('#newvet_modify_polygon_button').removeClass 'ui-state-active'

        this._updateNewVetHint()

        null

    _activateDrawPolygonMode: () ->
        this._clearNewVettingMode()
        $('#newvet_draw_polygon_button').addClass 'ui-state-active'
        @drawControl.activate()
        this._updateNewVetHint()

        null

    _activateModifyPolygonMode: () ->
        this._clearNewVettingMode()
        $('#newvet_modify_polygon_button').addClass 'ui-state-active'

        # Specify the modify mode as reshape and drag 
        @modifyControl.mode = OpenLayers.Control.ModifyFeature.RESHAPE | OpenLayers.Control.ModifyFeature.DRAG
        @modifyControl.activate()
        this._updateNewVetHint()

    _handleToggleButtonClick: (e, onActivatingButton, onDeactivatingButton) ->
        e.preventDefault()
        if $(e.srcElement).hasClass 'ui-state-active'
            # Run in the scope of this
            onDeactivatingButton.call(this)
        else
            # Run in the scope of this
            onActivatingButton.call(this)

        null

    _handleDrawPolygonClick: (e) ->
        this._handleToggleButtonClick(e, this._activateDrawPolygonMode, this._clearNewVettingMode)

        null

    _handleModifyPolygonClick: (e) ->
        this._handleToggleButtonClick(e, this._activateModifyPolygonMode, this._clearNewVettingMode)

        null

    _handleAddPolygonClick: (e) ->
        e.preventDefault()

        this._clearNewVettingMode()

        # Determine position to add polygon..
        # then add it.
        # Get the center of the map.
        centerOfMap = Edgar.map.getCenter()
        mapBounds   = Edgar.map.getExtent()
        mapHeight   = ( mapBounds.top   - mapBounds.bottom )
        mapWidth    = ( mapBounds.right - mapBounds.left )

        calcDimension = null
        if (mapHeight > mapWidth)
            calcDimension = mapHeight
        else
            calcDimension = mapWidth

        minorFraction = calcDimension / 14

        radius = minorFraction # in map units (mercator - i.e. meters)
        sides = 6
        rotation = Math.random() * 360 # (in degrees)
        centerPoint = new OpenLayers.Geometry.Point(centerOfMap.lon, centerOfMap.lat)
        # create a polygon
        polygon = OpenLayers.Geometry.Polygon.createRegularPolygon(
            centerPoint
            radius
            sides
            rotation
        )

        # create some attributes for the feature
        attributes = {}

        feature = new OpenLayers.Feature.Vector polygon, attributes
        @vectorLayer.addFeatures [feature]

        consolelog(@vectorLayer.features);

        this._activateModifyPolygonMode()

        null

    _removeAllFeatures: () ->
        @vectorLayer.removeFeatures @vectorLayer.features

    _removeModifyFeatureHandlesAndVertices: () ->
        # Delete any modify control vertices.
        @vectorLayer.removeFeatures @modifyControl.virtualVertices, { silent: true }
        @vectorLayer.removeFeatures @modifyControl.vertices, { silent: true }
        # Delete the radius handle.
        @vectorLayer.removeFeatures @modifyControl.radiusHandle, { silent: true }
        # Delete the drag handle.
        @vectorLayer.removeFeatures @modifyControl.dragHandle, { silent: true }

        null

    _handleDeleteSelectedPolygonClick: (e) ->
        e.preventDefault()
        currentFeature =  @modifyControl.feature

        if(currentFeature)
            # Unselect the feature.
            @modifyControl.unselectFeature(currentFeature)
            this._removeModifyFeatureHandlesAndVertices()
            # Delete the selected feature
            @vectorLayer.removeFeatures(currentFeature)

            # If all Features are now deleted,
            # clear the vetting mode (get out of modify mode)
            if @vectorLayer.features.length == 0
                this._clearNewVettingMode()

        null


    _handleDeleteAllPolygonClick: (e) ->
        e.preventDefault()

        this._clearNewVettingMode()

        @vectorLayer.removeAllFeatures()

        this._updateNewVetHint()

        null


    # Sets the vetting hint to a random hint
    _updateNewVetHint: () ->
        drawPolygonHints = [
            ''
        ]

        modifyPolygonHints = [
            '<p>Press the <strong>Delete</strong> key while hovering your mouse cursor over a corner to delete it</p>'
        ]

        movePolygonHints = [
            ''
        ]

        # Modify feature is active
        if @modifyControl.active
            hint = modifyPolygonHints[Math.floor(Math.random()*modifyPolygonHints.length)]
            $('#vethint').html hint
        else if @drawControl.active
            hint = drawPolygonHints[Math.floor(Math.random()*drawPolygonHints.length)]
            $('#vethint').html hint
        else
            $('#vethint').html ''

        null


    _createNewVetting: () ->
        consolelog "Processing create new vetting"

        # Get features from the vector layer (which are all known to be polygons)
        newVetPolygonFeatures = @vectorLayer.features
        # Now convert our array of features into an array of geometries.
        newVetPolygonGeoms = []
        newVetPolygonGeoms.push(feature.geometry) for feature in newVetPolygonFeatures

        # Create a MultiPolygon from our polygons.
        newVetPolygon = new OpenLayers.Geometry.MultiPolygon newVetPolygonGeoms
        consolelog "WKT logs:"
        consolelog "polygon", newVetPolygon

        # Get WKT (well known text) for the multipolygon
        layerWKTString = @wkt.extractGeometry(newVetPolygon)
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
        url = ( Edgar.baseUrl + "species/insert_vetting/" + speciesId + ".json" )

        # TODO
        # disable save button

        # Send the new vet to the back-end
        $.ajax(
            url
            {
                type: "POST",
                data: vetDataAsJSONString,
                success: (data, textStatus, jqXHR) =>
                    alert "Successfully created your vetting"
                    # okay.. we did it..
                    # remove all the features from the new vetting interface
                    # clear the new vetting mode
                    # clear the new vetting form
                    # refresh the my features vetting interface
                    this._removeAllFeatures()
                    this._clearNewVettingMode()
                    this._clearVettingFormFields()
                    Edgar.vetting.myHabitatClassifications.refresh()
                error: (jqXHR, textStatus, errorThrown) =>
                    alert "Failed to create vetting: " + errorThrown + ". Please ensure your classified area is a simple polygon (i.e. its boundaries don't cross each other)"
                complete: (jqXHR, textStatus) =>
                    # TODO
                    # re-enable save button
                dataType: 'json'
            }
        )

        true

    ###
    # Clear the new vetting form fields
    ###
    _clearVettingFormFields: () ->
        $("#vetcomment").val('')
        $("#vetclassification").val('')
        this

    # Returns true if valid
    # Returns false else
    _validateNewVetForm: () ->

        # Get features from the vector layer (which are all known to be polygons)
        newVetPolygonFeatures = @vectorLayer.features

        if (Edgar.mapdata.species == null)
            alert "No species selected"
            false
        else if (newVetPolygonFeatures.length == 0)
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
