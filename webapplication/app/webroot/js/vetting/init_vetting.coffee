###
File to control entering and exiting vetting modes.
###

Edgar.vetting = {}

###
get ready to do vetting.  gets called by mapmodes.js, after
the vetting tools have been switched on
###
Edgar.vetting.engageVettingMode = () ->
    console.log "engageVettingMode"
    null

###
wrap up the vetting mode.  gets called by mapmodes.js, before
the vetting tools have been hidden
###
Edgar.vetting.disengageVettingMode = () ->
    console.log "disengageVettingMode"
    null


