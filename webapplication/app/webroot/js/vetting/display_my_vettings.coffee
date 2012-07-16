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

        # TODO
        #
        # Attach button handlers here....
        # ----------------------------

        consolelog "Finished init-ing the classify habitat interface"

        null

    _addVectorLayer: () ->
        this.vectorLayer = new OpenLayers.Layer.Vector('My Habitat Classifications', {
            isBaseLayer: false
            projection: Edgar.util.projections.geographic
            strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})]
            protocol: new OpenLayers.Protocol.HTTP({
                url: (Edgar.baseUrl + "species/vetting_geo_json/" + Edgar.mapdata.species.id + ".json")
                format: new OpenLayers.Format.GeoJSON({})
                params: {
                    by_user_id: Edgar.user.id
                }
            })
            styleMap: Edgar.vetting.areaStyleMap
        });
        Edgar.map.addLayer(this.vectorLayer)

    _removeVectorLayer: () ->
        Edgar.map.removeLayer(this.vectorLayer)
        delete this.vectorLayer

        null

    _addSelectControl: () ->
        this.selectControl = new OpenLayers.Control.SelectFeature this.vectorLayer
        Edgar.map.addControl(this.selectControl)

    _removeSelectControl: () ->
        Edgar.map.removeControl(this.selectControl)

    _addLoadEndListener: () ->
        this.vectorLayer.events.register('loadend', this, this._vectorLayerUpdated)

    _removeLoadEndListener: () ->
        this.vectorLayer.events.unregister('loadend', this, this._vectorLayerUpdated)

    _vectorLayerUpdated: () ->
        # Clear the list of existing features
        $myVettingsList = $('#my_vettings_list');
        $myVettingsList.empty();

        # Process Vetting Layer Features.
        features = this.vectorLayer.features

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
                    Edgar.vetting.myHabitatClassifications.selectControl.select(thisFeature)
                    $(this).addClass("ui-state-hover")
                () ->
                    Edgar.vetting.myHabitatClassifications.selectControl.unselectAll();
                    $(this).removeClass("ui-state-hover")
            )

            $ul.append($liVetting)

        addVettingToVettingsList(feature, $myVettingsList) for feature in features

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
}
