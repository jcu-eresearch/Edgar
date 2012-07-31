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
        $longitude = (float)(string) $location['longitude'];
        $latitude = (float)(string) $location['latitude'];

        $contentious_count = $location['contentious_count'];
        $source_classification = $location['source_classification'];
        $source_classification = (!isset($source_classification) || is_null($source_classification)) ? "N/A" : $source_classification;
        $classification = $location['classification'];
        $classification = (!isset($classification) || is_null($classification)) ? "N/A" : $classification;
        $count = $location['total_occurrences'];

        $point_radius = is_null($round_to_nearest_nth_fraction) ? GeolocationsBehavior::MIN_FEATURE_RADIUS : ( floor(log($count, 2) * 0.5 ) + GeolocationsBehavior::MIN_FEATURE_RADIUS);

        $classification_count_array = array(
            "unknown" => $location["unknown_count"],
            "invalid" => $location["invalid_count"],
            "historic" => $location["historic_count"],
            "vagrant" => $location["vagrant_count"],
            "irruptive" => $location["irruptive_count"],
            "non breeding" => $location["non_breeding_count"],
            "introduced non breeding" => $location["introduced_non_breeding_count"],
            "breeding" => $location["breeding_count"],
            "introduced breeding" => $location["introduced_breeding_count"]
        );
        arsort($classification_count_array);

        $major_classification = null;
        $minor_classification = null;

        $major_classification_count = null;
        $minor_classification_count = null;

        $class_keys = array_keys($classification_count_array);
        $class_counts = array_values($classification_count_array);

        $major_classification = $class_keys[0];
        $major_classification_count = $class_counts[0];
        if ($class_counts[1] > 0) {
            $minor_classification = $class_keys[1];
            $minor_classification_count = $class_counts[1];
        } else {
            $minor_classification = $major_classification;
        }

        $major_classification_properties = Vetting::getPropertiesJSONObject($major_classification);
        $minor_classification_properties = Vetting::getPropertiesJSONObject($minor_classification);

        $properties_array = array();

        // Use the vetting classification's fill color to represent the classification
        $properties_array['stroke_color'] = $major_classification_properties['fill_color'];
        $properties_array['fill_color']   = $minor_classification_properties['fill_color'];
        $properties_array['title'] = '';
        $properties_array['occurrence_type'] = 'dotgriddetail';
        $properties_array['description'] = "".
                    "<dl>".
                    "<dt>Latitude</dt><dd>$latitude</dd>".
                    "<dt>Longitude</dt><dd>$longitude</dd>".
                    "<dt>Cluster Size</dt><dd>$count</dd>".
                    "<dt>Contentious</dt><dd>$contentious_count</dd>".
                    "</dl>";
        $properties_array['point_radius'] = $point_radius;
        $properties_array['stroke_width'] = $point_radius;

        $location_features[] = array(
            "type" => "Feature",
            'properties' => $properties_array,
            'geometry' => array(
                'type' => 'Point',
                'coordinates' => array($longitude, $latitude),
            ),
        );
    }

    return $location_features;
}

