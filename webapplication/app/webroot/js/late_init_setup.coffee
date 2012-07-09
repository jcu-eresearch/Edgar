###
initialise some global variables.
these globals need to wait for the other files to be loaded (such as OpenLayers)
###

###
Projections
----------
###
Edgar.util =
        projections:
            # DecLat, DecLng 
            geographic: new OpenLayers.Projection "EPSG:4326"
            # Spherical Meters
            mercator:   new OpenLayers.Projection "EPSG:900913"
