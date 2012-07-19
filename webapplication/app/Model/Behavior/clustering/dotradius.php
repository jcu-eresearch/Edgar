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
        $contentious = $location['contentious'] ? "true" : "false";
        $source_classification = $location['source_classification'];
        $source_classification = (!isset($source_classification) || is_null($source_classification)) ? "N/A" : $source_classification;
        $classification = $location['classification'];
        $classification = (!isset($classification) || is_null($classification)) ? "N/A" : $classification;

        if ($source_classification == "unknown") {
            $source_classification = "unclassified";
        }

        $location_features[] = array(
            "type" => "Feature",
            'properties' => array(
                'title' => '',
                'occurrence_type' => 'dotradius',
                'description' => 
                    "<dl>".
                    "<dt>Latitude</dt><dd>$latitude</dd>".
                    "<dt>Longitude</dt><dd>$longitude</dd>".
                    "<dt>Our Classification</dt><dd>$classification</dd>".
                    "<dt>Contentious</dt><dd>$contentious</dd>".
                    "<dt>Source</dt><dd><a href='http://www.ala.org.au/'>Atlas of Living Australia</a></dd>".
                    "<dt>Source Classification</dt><dd>$source_classification</dd>".
                    "</dl>",
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

