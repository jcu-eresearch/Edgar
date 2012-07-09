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

        Edgar.vetting.wkt = new OpenLayers.Format.WKT {
            'internalProjection': Edgar.map.baseLayer.projection,
            'externalProjection': Edgar.util.projections.mercator
        }

        consolelog "Finished init-ing the classify habitat interface"

        null
}
