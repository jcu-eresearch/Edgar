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
function get_features_dotradius(Model $Model, $bounds = null) {
    $location_features = array();

    foreach($Model->occurrencesInBounds($bounds) as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];
        $location_features[] = array(
            "type" => "Feature",
            'properties' => array(
                'title' => "Occurrence",
                'occurrence_type' => 'dotradius',
                'description' => "<dl><dt>Latitude</dt><dd>$latitude</dd><dt>Longitude</dt><dd>$longitude</dd>",
                'point_radius' => GeolocationsBehavior::NON_CLUSTERED_FEATURE_RADIUS,
            ),
            'geometry' => array(
                'type' => 'Point',
                'coordinates' => array($longitude, $latitude),
            ),
        );
    }

    return $location_features;
}

