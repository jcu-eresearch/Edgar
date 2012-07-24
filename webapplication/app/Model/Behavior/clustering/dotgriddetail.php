<?php

function get_features_dotgrid_detail(Model $Model, $bounds) {
    $location_features = array();

    $lat_range = $bounds['max_latitude']  - $bounds['min_latitude'];
    $lng_range = $bounds['max_longitude'] - $bounds['min_longitude'];

    $lat_lng_range_avg = ( array_sum( array($lat_range, $lng_range) ) / 2 );

    // Range to decimal place conversions

    // 100 = 0,
    // 50 = 1,
    // 25 = 1,
    // 12.5  = 3,
    // 7.5  = 4
    // 2  = 16
    // 1  = 33
    // 0.1  = 332
    // 0  = div by zero err
    $round_to_x_dec = (int) ( 10 / log(pow(2, $lat_lng_range_avg), 10) );

    foreach($Model->detailedClusteredOccurrencesInBounds($bounds, $round_to_x_dec) as $location) {
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

