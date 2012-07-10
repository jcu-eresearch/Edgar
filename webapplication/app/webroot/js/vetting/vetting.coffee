###
File to control entering and exiting vetting modes.
###

Edgar.vetting = {

    ###
    Initialise the classify habitat interface
    ###
    init: () ->
        Edgar.vetting.classifyHabitat.init()

        null

    ###
    get ready to do vetting.  gets called by mapmodes.js, after
    the vetting tools have been switched on
    ###
    engageVettingMode: () ->
        console.log "engageVettingMode"
        Edgar.vetting.classifyHabitat.engage()

        null

    ###
    wrap up the vetting mode.  gets called by mapmodes.js, before
    the vetting tools have been hidden
    ###
    disengageVettingMode: () ->
        console.log "disengageVettingMode"

        null
}

###
Document Ready..
###
$ ->
    Edgar.vetting.init()
