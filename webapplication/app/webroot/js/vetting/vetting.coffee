###
# File to control entering and exiting vetting modes.
###

Edgar.vetting = {

    ###
    # Initialise the classify habitat interface
    ###
    init: () ->
        Edgar.vetting.classifyHabitat.init()

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
            if this.classifyHabitat.isChangeModeOkay(newMode)
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
        Edgar.vetting.classifyHabitat.engage()

        null

    ###
    # wrap up the vetting mode.  gets called by mapmodes.js, before
    # the vetting tools have been hidden
    ###
    disengageVettingMode: () ->
        console.log "disengageVettingMode"
        Edgar.vetting.classifyHabitat.disengage()

        null

}

###
# Document Ready..
###
$ ->
    Edgar.vetting.init()
