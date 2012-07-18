###
# Code to control the classify a habitat interface
###

Edgar.vetting.myHabitatClassifications = {

    ###
    # Init the my habitat classifications
    #
    # This is run once
    ###
    init: () ->
        consolelog "Starting to init the my habitat classifications interface"
        # Place holder
        # put any future init code here
        consolelog "Finished init-ing the classify habitat interface"

        null

    _addVectorLayer: () ->
        @vectorLayer = new OpenLayers.Layer.Vector('My Habitat Classifications', {
            isBaseLayer: false
            projection: Edgar.util.projections.geographic
            strategies: [new OpenLayers.Strategy.Fixed()]
            protocol: new OpenLayers.Protocol.HTTP({
                url: (Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json")
                format: new OpenLayers.Format.GeoJSON({})
                params: {
                    by_user_id: Edgar.user.id
                }
            })
            styleMap: Edgar.vetting.areaStyleMap
        });
        Edgar.map.addLayer(@vectorLayer)

    _removeVectorLayer: () ->
        Edgar.map.removeLayer(@vectorLayer)
        delete @vectorLayer

        null

    _addSelectControl: () ->
        @selectControl = new OpenLayers.Control.SelectFeature @vectorLayer
        Edgar.map.addControl(@selectControl)

    _removeSelectControl: () ->
        Edgar.map.removeControl(@selectControl)

    _addLoadEndListener: () ->
        @vectorLayer.events.register('loadend', this, this._vectorLayerUpdated)

    _removeLoadEndListener: () ->
        @vectorLayer.events.unregister('loadend', this, this._vectorLayerUpdated)

    _addVettingToVettingsList: (feature, $ul) ->
        featureData    = feature.data
        classification = featureData['classification']
        comment        = featureData['comment']
        vettingId      = featureData['vetting_id']

        # Create the delete button
        $deleteButton = $('<button class="ui-state-default ui-corner-all delete_polygon"' +
                         'title="modify areas"><span class="ui-icon ui-icon-trash">' +
                          '</span></button>')

        # Click handler for the delete button
        $deleteButton.click( (e) =>
            url = ( Edgar.baseUrl + "vettings/delete/" + vettingId + ".json" )
            $.ajax(
                url
                {
                    type: "POST",
                    data: {},
                    success: (data, textStatus, jqXHR) =>
                        alert "Successfully deleted your vetting (" + vettingId + ")"
                        # refresh the my features vetting interface
                        this.refresh()
                    error: (jqXHR, textStatus, errorThrown) =>
                        consolelog("Failed to del vetting", jqXHR, textStatus, errorThrown);
                        alert "Failed to delete your vetting: " + errorThrown + "(" + vettingId + ")"
                    complete: (jqXHR, textStatus) =>
                    dataType: 'json'
                }
            )
            null
        )

        # Create a list item for the vetting
        $liVetting     = $('<li class="ui-state-default vetting_listing"><span class="classification">' +
                         classification + '</span><span class="comment">' + 
                         comment +
                         '</span>' +
                         '</li>')
        # Prepend the button to the list item vetting
        $liVetting.prepend($deleteButton)

        # Add a hover handler to highlight the associated feature
        $liVetting.data('feature', feature)
        $liVetting.hover(
            () ->
                thisFeature = $(this).data('feature')
                Edgar.vetting.myHabitatClassifications.selectControl.select(thisFeature)
                $(this).addClass("ui-state-hover")
            () ->
                Edgar.vetting.myHabitatClassifications.selectControl.unselectAll();
                $(this).removeClass("ui-state-hover")
        )

        $ul.append($liVetting)

    _vectorLayerUpdated: () ->
        # Clear the list of existing features
        $myVettingsList = $('#my_vettings_list');
        $myVettingsList.empty();

        # Process Vetting Layer Features.
        features = @vectorLayer.features

        this._addVettingToVettingsList(feature, $myVettingsList) for feature in features

        null

    engage: () ->
        consolelog "Starting engageMyHabitatClassifications"

        this._addVectorLayer()
        this._addSelectControl()
        this._addLoadEndListener()
        this._vectorLayerUpdated()

        consolelog "Finished engageMyHabitatClassifications"

        null

    disengage: () ->
        consolelog "Starting disengageMyHabitatClassifications"

        this._removeLoadEndListener()
        this._removeSelectControl()
        this._removeVectorLayer()

        consolelog "Finished disengageMyHabitatClassifications"

    isChangeModeOkay: (newMode) ->
        true

    refresh: () ->
        if ( 'vectorLayer' of this )
            @vectorLayer.refresh({ force: true })
            true
        else
            false
}
