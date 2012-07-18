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
                "Discard area classification": () ->
                    $( this ).dialog( "close" )
                    Edgar.vetting.classifyHabitat._removeAllFeatures()
                    $(Edgar.map).trigger 'changemode', $( this ).data('newMode')
                Cancel: () ->
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
        handle add polygon by occurrences press
        ###
        $('#newvet_add_polygon_by_occurrences_button').click( (e) =>
            this._handleAddPolygonByOccurrencesClick e
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
        this._addDrawBoundingBoxControl()
        this._addModifyControl()

        consolelog "Finished engageClassifyHabitatInterface"

        null

    disengage: () ->
        consolelog "Starting disengageClassifyHabitatInterface"

        this._clearNewVettingMode()

        this._removeDrawBoundingBoxControl()
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

    _addDrawBoundingBoxControl: () ->
        @drawBoundingBoxControl = new OpenLayers.Control.DrawFeature(
            @vectorLayer
            OpenLayers.Handler.RegularPolygon, {
                handlerOptions: {
                    sides: 4
                    irregular: true
                }
            }
        )

        @drawBoundingBoxControl.featureAdded = (feature) =>
            geom = feature.geometry
            geomBounds = geom.getBounds()
            @vectorLayer.removeFeatures([feature])

            occurrencesLayer = window.Edgar.occurrences.vectorLayer
            occurrenceClusterFeatures = occurrencesLayer.features

            featuresWithinBounds = []
            addPolygonIfWithinBounds = (clusterFeature, bounds, arrayToAppendTo) =>
                featureCentroid = clusterFeature.geometry.getCentroid()
                isFeatureWithinBounds = bounds.contains(featureCentroid.x, featureCentroid.y)
                if isFeatureWithinBounds
                    arrayToAppendTo.push(clusterFeature)

            addPolygonIfWithinBounds(feature, geomBounds, featuresWithinBounds) for feature in occurrenceClusterFeatures

            polygonsToAdd = []
            for feature in featuresWithinBounds
                consolelog featureOccurrence

                min_latitude_range  = feature.attributes['min_latitude_range']
                max_latitude_range  = feature.attributes['max_latitude_range']
                min_longitude_range = feature.attributes['min_longitude_range']
                max_longitude_range = feature.attributes['max_longitude_range']


                points = [
                    (new OpenLayers.Geometry.Point(min_longitude_range, min_latitude_range)).transform(Edgar.util.projections.geographic, Edgar.util.projections.mercator)
                    (new OpenLayers.Geometry.Point(min_longitude_range, max_latitude_range)).transform(Edgar.util.projections.geographic, Edgar.util.projections.mercator)
                    (new OpenLayers.Geometry.Point(max_longitude_range, max_latitude_range)).transform(Edgar.util.projections.geographic, Edgar.util.projections.mercator)
                    (new OpenLayers.Geometry.Point(max_longitude_range, min_latitude_range)).transform(Edgar.util.projections.geographic, Edgar.util.projections.mercator)
                ]

                consolelog("POINTS")
                consolelog(points)

                edgeLine = new OpenLayers.Geometry.LinearRing(points)

                # create a polygon
                polygon = new OpenLayers.Geometry.Polygon(edgeLine)

                # create some attributes for the feature
                attributes = {}

                featureOccurrence = new OpenLayers.Feature.Vector polygon, attributes
                @vectorLayer.addFeatures [featureOccurrence]

            this._activateModifyPolygonMode()

        Edgar.map.addControl @drawBoundingBoxControl

    _shareAnEdge: (polygonA, polygonB) ->
        # check for shared edge
        false

    _simplifyPolygons: (polygonsInput) ->
        resultPolygons = []

        buckets = []

        for polygon in polygonsInput
            foundBucket = null
            for bucket in buckets
                # first, look for ourselves
                featureIndex = bucket.indexOf(polygon)
                if featureIndex != -1
                    foundBucket = bucket
                    break

            for otherPolygon in polygonsInput
                if polygon != otherPolygon
                    # if this polygon and otherPolygon share a common edge, put them in the same bucket
                    # if neither polygon is already in a bucket, create a bucket, and stick them in the bucket.
                    if _shareAnEdge(polygon, otherPolygon)
                        if foundBucket == null
                            for bucket in buckets
                                # first, look for ourselves
                                featureIndex = bucket.indexOf(otherPolygon)
                                if featureIndex != -1
                                    foundBucket = bucket
                                    break

                        if foundBucket == null
                            newBucket = []
                            buckets.push(newBucket)
                            foundBucket = newBucket
                            foundBucket.push(otherPolygon)

                        foundBucket.push(polygon)

        resultPolygons

    ###
    # Removes the draw control
    # Note: Assumes _clearNewVettingMode was already run
    ###
    _removeDrawControl: () ->
        @drawControl.map.removeControl @drawControl
        delete @drawControl

        null

    ###
    # Removes the draw bounding box control
    # Note: Assumes _clearNewVettingMode was already run
    ###
    _removeDrawBoundingBoxControl: () ->
        @drawBoundingBoxControl.map.removeControl @drawBoundingBoxControl
        delete @drawBoundingBoxControl

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

        # Deactivate draw bounding box control
        @drawBoundingBoxControl.deactivate()
        $('#newvet_add_polygon_by_occurrences_button').removeClass 'ui-state-active'

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

    _handleAddPolygonByOccurrencesClick: (e) ->
        e.preventDefault()
        this._handleToggleButtonClick(e, this._activateAddPolygonByOccurrenceMode, this._clearNewVettingMode)

        null

    _activateAddPolygonByOccurrenceMode: () ->
        this._clearNewVettingMode()
        $('#newvet_add_polygon_by_occurrences_button').addClass 'ui-state-active'
        @drawBoundingBoxControl.activate()
        this._updateNewVetHint()

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
        url = ( Edgar.baseUrl + "species/add_vetting/" + speciesId + ".json" )

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
