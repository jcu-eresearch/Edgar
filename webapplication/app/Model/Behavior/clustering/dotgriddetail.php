<?php

function get_features_dotgrid_detail(Model $Model, $bounds ) {
    $location_features = array();

    foreach($Model->detailedClusteredOccurrencesInBounds($bounds) as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];
        $contentious = $location['contentious'] ? "yes" : "no";
        $source_classification = $location['source_classification'];
        $source_classification = (!isset($source_classification) || is_null($source_classification)) ? "N/A" : $source_classification;
        $classification = $location['classification'];
        $classification = (!isset($classification) || is_null($classification)) ? "N/A" : $classification;

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

