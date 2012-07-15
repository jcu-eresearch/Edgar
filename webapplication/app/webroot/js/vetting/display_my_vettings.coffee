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

    engage: () ->
        consolelog "Starting engageMyHabitatClassifications"

        this._addVectorLayer()

        consolelog "Finished engageMyHabitatClassifications"

        null

    disengage: () ->
        consolelog "Starting disengageMyHabitatClassifications"

        this._removeVectorLayer()

        consolelog "Finished disengageMyHabitatClassifications"

    isChangeModeOkay: (newMode) ->
        true
}
