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
        this.vectorLayer = new OpenLayers.Layer.Vector('Their Habitat Classifications', {
            isBaseLayer: false
            projection: Edgar.util.projections.geographic
            strategies: [new OpenLayers.Strategy.BBOX({resFactor: 1.1})]
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
        Edgar.map.addLayer(this.vectorLayer)

    _removeVectorLayer: () ->
        Edgar.map.removeLayer(this.vectorLayer)
        delete this.vectorLayer

        null

    engage: () ->
        consolelog "Starting engageTheirHabitatClassifications"

        this._addVectorLayer()

        consolelog "Finished engageTheirHabitatClassifications"

        null

    disengage: () ->
        consolelog "Starting disengageTheirHabitatClassifications"

        this._removeVectorLayer()

        consolelog "Finished disengageTheirHabitatClassifications"

    isChangeModeOkay: (newMode) ->
        true
}
