###
# Code to control the classify a habitat interface
###

Edgar.vetting.theirHabitatClassifications = {

    ###
    # Init the their habitat classifications
    #
    # This is run once
    ###
    init: () ->
        consolelog "Starting to init the their habitat classifications interface"

        # TODO
        #
        # Attach button handlers here....
        # ----------------------------

        consolelog "Finished init-ing the classify their habitat interface"

        null

    _addVectorLayer: () ->
        @vectorLayer = new OpenLayers.Layer.Vector('Their Habitat Classifications', {
            displayInLayerSwitcher: false
            isBaseLayer: false
            projection: Edgar.util.projections.geographic
            strategies: [new OpenLayers.Strategy.Fixed()]
            protocol: new OpenLayers.Protocol.HTTP({
                url: (Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json")
                format: new OpenLayers.Format.GeoJSON({})
                params: {
                    by_user_id: Edgar.user.id
                    inverse_user_id_filter: true
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

    _vectorLayerUpdated: () ->
        # Clear the list of existing features
        $myVettingsList = $('#their_vettings_list');
        $myVettingsList.empty();

        # Process Vetting Layer Features.
        features = @vectorLayer.features

        addVettingToVettingsList = (feature, $ul) ->
            featureData    = feature.data
            classification = featureData['classification']
            comment        = featureData['comment']
            $liVetting     = $('<li class="ui-state-default"><span class="classification">' +
                             classification + '</span><span class="comment">' + 
                             comment +
                             '</span></li>')

            $liVetting.data('feature', feature)
            $liVetting.hover(
                () ->
                    thisFeature = $(this).data('feature')
                    Edgar.vetting.theirHabitatClassifications.selectControl.select(thisFeature)
                    $(this).addClass("ui-state-hover")
                () ->
                    Edgar.vetting.theirHabitatClassifications.selectControl.unselectAll();
                    $(this).removeClass("ui-state-hover")
            )

            $ul.append($liVetting)

        addVettingToVettingsList(feature, $myVettingsList) for feature in features

        null


    engage: () ->
        consolelog "Starting engageTheirHabitatClassifications"

        this._addVectorLayer()
        this._addSelectControl()
        this._addLoadEndListener()
        this._vectorLayerUpdated()

        consolelog "Finished engageTheirHabitatClassifications"

        null

    disengage: () ->
        consolelog "Starting disengageTheirHabitatClassifications"

        this._removeLoadEndListener()
        this._removeSelectControl()
        this._removeVectorLayer()

        consolelog "Finished disengageTheirHabitatClassifications"

    isChangeModeOkay: (newMode) ->
        true
}
