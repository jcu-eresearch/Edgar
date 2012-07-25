<?php

function get_features_dotgrid_detail(Model $Model, $bounds) {
    $location_features = array();

    $lat_range = $bounds['max_latitude']  - $bounds['min_latitude'];
    $lng_range = $bounds['max_longitude'] - $bounds['min_longitude'];

    $lat_lng_range_avg = ( array_sum( array($lat_range, $lng_range) ) / 2 );

    // Range to decimal place conversions
    $round_to_nearest_nth_fraction = 1;
    if ($lat_lng_range_avg > 200) {
        $round_to_nearest_nth_fraction = 0.25;
    } elseif ($lat_lng_range_avg > 100) {
        $round_to_nearest_nth_fraction = 0.5;
    } elseif ($lat_lng_range_avg > 50) {
        $round_to_nearest_nth_fraction = 1;
    } elseif ($lat_lng_range_avg > 25) {
        $round_to_nearest_nth_fraction = 2;
    } elseif ($lat_lng_range_avg > 10) {
        $round_to_nearest_nth_fraction = 4;
    } elseif ($lat_lng_range_avg > 5) {
        $round_to_nearest_nth_fraction = 8;
    } elseif ($lat_lng_range_avg > 2) {
        $round_to_nearest_nth_fraction = 16;
    } else {
        $round_to_nearest_nth_fraction = null;
    }

    # if round_to_nearest_nth_fraction null, don't round
    foreach($Model->detailedClusteredOccurrencesInBounds($bounds, $round_to_nearest_nth_fraction) as $location) {
        $longitude = $location['longitude'];
        $latitude = $location['latitude'];
        $contentious = $location['contentious'] ? "yes" : "no";
        $source_classification = $location['source_classification'];
        $source_classification = (!isset($source_classification) || is_null($source_classification)) ? "N/A" : $source_classification;
        $classification = $location['classification'];
        $classification = (!isset($classification) || is_null($classification)) ? "N/A" : $classification;
        $count = $location['total_classification_count'];

        $point_radius = ( floor(log($count, 2) ) + GeolocationsBehavior::MIN_FEATURE_RADIUS);

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
                    "<dt>Cluster Rounded to nth of a degree</dt><dd>$round_to_nearest_nth_fraction</dd>".
                    "</dl>",
                'point_radius' => is_null($round_to_nearest_nth_fraction) ? GeolocationsBehavior::MIN_FEATURE_RADIUS : $point_radius
            ),
            'geometry' => array(
                'type' => 'Point',
                'coordinates' => array($longitude, $latitude),
            ),
        );
    }

    return $location_features;
}

