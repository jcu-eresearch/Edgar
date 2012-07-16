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
        $myVettingsList = $('#my_vettings_list');
        $myVettingsList.empty();

        # Process Vetting Layer Features.
        features = @vectorLayer.features

        addVettingToVettingsList = (feature, $ul) ->
            featureData    = feature.data
            classification = featureData['classification']
            comment        = featureData['comment']
            $liVetting     = $('<li class="ui-state-default vetting_listing"><span class="classification">' +
                             classification + '</span><span class="comment">' + 
                             comment +
                             '</span>' +
                             '<button class="ui-state-default ui-corner-all delete_polygon"' +
                             'title="modify areas"><span class="ui-icon ui-icon-trash">' +
                             '</span></button>' +
                             '</li>')

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

    refresh: () ->
        if ( 'vectorLayer' of this )
            @vectorLayer.refresh({ force: true })
            true
        else
            false
}
