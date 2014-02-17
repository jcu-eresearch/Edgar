###
initialise some global variables and whatnot
###

###
the global Edgar object
###
window.Edgar = window.Edgar || {}

###
the species map itself
###
Edgar.map = Edgar.map || null

###
mode: one of 'blank', 'current', 'future', 'vetting'
don't set this directly, use:    $(Edgar.map).trigger('changemode','future'); // to change into future mode, for example
###
Edgar.mapmode = Edgar.mapmode || 'blank'

###
vars related to the species map
###
Edgar.mapdata = Edgar.mapdata || {}

Edgar.mapdata.species = null # (object) current species displayed on the map
Edgar.mapdata.emissionScenario = null #(string) identifier for current emission scenario
Edgar.mapdata.year = null #(integer) the year that the suitability map represents (e.g. 2010)

Edgar.mapdata.layers = {}  # references to OpenLayers layers to make them easy to remove etc
Edgar.mapdata.layers.currentsuitability = null
Edgar.mapdata.layers.occurrences = null
Edgar.mapdata.layers.selectoccurrencecontrol = null   # not technically a layer..

Edgar.mapdata.controls = {}  # references to OpenLayers controls to make them easy to enable/disable etc
Edgar.mapdata.controls.occurrencesSelectControl = null

###
logged in user?  This is set in fullscreencontent.ctp if there's a logged in user
###
Edgar.user = Edgar.user || null

Edgar.util = Edgar.util || {}

###
humanise where possible
###
Edgar.util.pluralise = (count, noun, plural) ->
    if count == 1
        count + " " + noun
    else if plural
        count + " " + plural
    else
        count + " " + noun + "s"

Edgar.util.showhide = (showlist, hidelist) ->
    $.each(hidelist,
        (i, itemid) ->
            $item = $('#' + itemid)
            if $item.css('display') != 'none' # apparently in Chrome .is(':visible') doesn't always return true when it should
                $item.hide('blind','fast')
    )

    $.each(showlist,
        (i, itemid) ->
            $item = $('#' + itemid)
#           if $item.css('display') == 'none' or $item.is(":visible") == false
            $item.show('blind','fast')
    )

# return a map path for a climate suitability map, given a species, year, and
# emission scenario.
# Arg 'species' can be a species id or a species object.
# Arg 'year' can be the string "current" or an number like 2035.
# Arg 'scenario' is ignored if the year is "current", otherwise is assumed to
# be the string name of the emission scenario
Edgar.util.mappath = (species, year, scenario) ->
    # find the species id
    speciesid = species
    if typeof species == 'object'
        speciesid = species.id

    if typeof year == 'string' and year.toLowerCase() == 'current'
        # find the current map for the species
        "#{speciesid}/1990.tif"
    else
        "#{speciesid}/#{scenario}_median_#{year}.tif"

