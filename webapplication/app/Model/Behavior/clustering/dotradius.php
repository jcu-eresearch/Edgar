<?php
    /**
     * Dump the object to a geoJSONArray
     *
     * If bounds are provided, only show locations within the provided bounds 
     * bounds is an array of min_latitude, max_latitude, min_longitude, max_longitude
     *
     * If clustered is true, then bounds are required.
     *
     * Clustered will return features in clusters, rather than a single feature per location.
     */
function get_features_dotradius(Model $Model, $bounds = array() ) {

    $locations = $Model->getLocationsArray();
    $location_features = array();

    foreach($locations as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];
        if ( GeolocationsBehavior::withinBounds($longitude, $latitude, $bounds) ) {
            $location_features[] = array(
                "type" => "Feature",
                'properties' => array(
                    'title' => "Occurrence",
                    'occurrence_type' => 'dotradius',
                    'description' => "<dl><dt>Latitude</dt><dd>$longitude</dd><dt>Longitude</dt><dd>$latitude</dd>",
                    'point_radius' => GeolocationsBehavior::NON_CLUSTERED_FEATURE_RADIUS,
                ),
                'geometry' => array(
                    'type' => 'Point',
                    'coordinates' => array($location['longitude'], $location['latitude']),
                ),
            );
        }
    }

    return $location_features;

}

