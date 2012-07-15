###
# File to control entering and exiting vetting modes.
###

Edgar.vetting = {

    ###
    # Define a style map for the vetting areas
    ###
    _initAreaStyleMap: () ->
        this.areaStyleMap = new OpenLayers.StyleMap({
            'default': {
                'fillOpacity':    0.3
                'strokeOpacity':  0.9
                'fillColor':     '${fill_color}'
                'strokeColor':   '${stroke_color}'
                'fontColor':     '${font_color}'
                'label':         '${classification}'
            }
            'select': {
                'fillOpacity':   1.0
                'strokeOpacity': 1.0
            }
        })

    ###
    # Initialise the classify habitat interface
    ###
    init: () ->
        Edgar.vetting.classifyHabitat.init()
        Edgar.vetting.myHabitatClassifications.init()
        Edgar.vetting.theirHabitatClassifications.init()

        this._initAreaStyleMap()

        this._bindToChangeModeEvents()

        null

    ###
    # Bind to the change mode events that occurr on the map
    ###
    _bindToChangeModeEvents: () ->
        $(Edgar.map).on(
            'changemode'
            (event, newMode) ->
                if not Edgar.vetting.isChangeModeOkay(newMode)
                    event.preventDefault()
        )

    isChangeModeOkay: (newMode) ->
        if Edgar.mapmode == 'vetting'
            if this.classifyHabitat.isChangeModeOkay(newMode) and this.myHabitatClassifications.isChangeModeOkay(newMode) and this.theirHabitatClassifications.isChangeModeOkay(newMode)
                true
            else
                consolelog('cancelling mode change.')
                false
        else
            true

    ###
    # get ready to do vetting.  gets called by mapmodes.js, after
    # the vetting tools have been switched on
    ###
    engageVettingMode: () ->
        console.log "engageVettingMode"
        Edgar.vetting.myHabitatClassifications.engage()
        Edgar.vetting.theirHabitatClassifications.engage()
        Edgar.vetting.classifyHabitat.engage()

        null

    ###
    # wrap up the vetting mode.  gets called by mapmodes.js, before
    # the vetting tools have been hidden
    ###
    disengageVettingMode: () ->
        console.log "disengageVettingMode"
        Edgar.vetting.myHabitatClassifications.disengage()
        Edgar.vetting.theirHabitatClassifications.disengage()
        Edgar.vetting.classifyHabitat.disengage()

        null

}

###
# Document Ready..
###
$ ->
    Edgar.vetting.init()
