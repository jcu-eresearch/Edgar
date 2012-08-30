<?php

function get_features_dotgrid_detail(Model $Model, $bounds, $offset=0, $limit=null, $options=array()) {

    $defaults = array(
        'trump' => false,
        'showdoubtful' => false,
        'showminor' => false,
        'griddiness' => 3.2 // lower number = bigger, more coarse grid squares
    );

    $options = array_merge($defaults, $options);

    $trump = $options["trump"];
    $showdoubtful = $options["showdoubtful"];
    $showminor = $options["showminor"];
    $griddiness = $options["griddiness"];

    // in trump mode, earlier listings will trump later ones when deciding colour
    $trumps = array(
        'unknown',

        'non-core',

        'vagrant',
        'irruptive',

        'core',
        'introduced',

        'historic',

        'doubtful'
    );


    $location_features = array();

    $lat_range = $bounds['max_latitude']  - $bounds['min_latitude'];
    $lng_range = $bounds['max_longitude'] - $bounds['min_longitude'];

    $lat_lng_range_avg = ( array_sum( array($lat_range, $lng_range) ) / 2 );

    // Range to decimal place conversions
    $cluster_by_rounding_to_nearest_nth_fraction = null;
    $vet_by_rounding_to_nearest_nth_fraction = 1;
    if ($lat_lng_range_avg > ($griddiness * 200)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 0.125;
        $vet_by_rounding_to_nearest_nth_fraction = 0.125;
    } elseif ($lat_lng_range_avg > ($griddiness * 100)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 0.25;
        $vet_by_rounding_to_nearest_nth_fraction = 0.25;
    } elseif ($lat_lng_range_avg > ($griddiness * 50)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 0.5;
        $vet_by_rounding_to_nearest_nth_fraction = 0.5;
    } elseif ($lat_lng_range_avg > ($griddiness * 25)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 1;
        $vet_by_rounding_to_nearest_nth_fraction = 1;
    } elseif ($lat_lng_range_avg > ($griddiness * 12)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 2;
        $vet_by_rounding_to_nearest_nth_fraction = 2;
    } elseif ($lat_lng_range_avg > ($griddiness * 5)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 4;
        $vet_by_rounding_to_nearest_nth_fraction = 4;
    } elseif ($lat_lng_range_avg > ($griddiness * 2)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 8;
        $vet_by_rounding_to_nearest_nth_fraction = 8;
    } elseif ($lat_lng_range_avg > ($griddiness * 1)) {
        $cluster_by_rounding_to_nearest_nth_fraction = 16;
        $vet_by_rounding_to_nearest_nth_fraction = 16;
    # don't cluster occurrences beyond this point
    # but do continue to calculate vetting areas
    } elseif ($lat_lng_range_avg > ($griddiness * 0.5)) {
        $vet_by_rounding_to_nearest_nth_fraction = 32;
    } elseif ($lat_lng_range_avg > ($griddiness * 0.25)) {
        $vet_by_rounding_to_nearest_nth_fraction = 64;
    } elseif ($lat_lng_range_avg > ($griddiness * 0.125)) {
        $vet_by_rounding_to_nearest_nth_fraction = 128;
    } elseif ($lat_lng_range_avg > ($griddiness * 0.05)) {
        $vet_by_rounding_to_nearest_nth_fraction = 256;
    } else {
        $vet_by_rounding_to_nearest_nth_fraction = 512;
    }

    # if cluster_by_rounding_to_nearest_nth_fraction null, don't round
    foreach($Model->detailedClusteredOccurrencesInBounds($bounds, $cluster_by_rounding_to_nearest_nth_fraction, $offset, $limit) as $location) {
        $longitude = (float)(string) $location['longitude'];
        $latitude = (float)(string) $location['latitude'];

        $contentious_count = $location['contentious_count'];
        $source_classification = $location['source_classification'];
        $source_classification = (!isset($source_classification) || is_null($source_classification)) ? "N/A" : $source_classification;
        $classification = $location['classification'];
        $classification = (!isset($classification) || is_null($classification)) ? "N/A" : $classification;
        $count = $location['total_occurrences'];

        $point_radius = is_null($cluster_by_rounding_to_nearest_nth_fraction) ? GeolocationsBehavior::MIN_FEATURE_RADIUS : ( floor(log($count, 2) * 0.5 ) + GeolocationsBehavior::MIN_FEATURE_RADIUS);

        $unsorted_contentious_classification_count_array = array(
            "unknown" => $location["contentious_unknown_count"],
            "historic" => $location["contentious_historic_count"],
            "vagrant" => $location["contentious_vagrant_count"],
            "irruptive" => $location["contentious_irruptive_count"],
            "core" => $location["contentious_core_count"],
            "introduced" => $location["contentious_introduced_count"]
        );

        $classification_count_array = array(
            "unknown" => $location["unknown_count"],

            "historic" => $location["historic_count"],
            "vagrant" => $location["vagrant_count"],
            "irruptive" => $location["irruptive_count"],
            "core" => $location["core_count"],
            "introduced" => $location["introduced_count"]
        );

        if ($showdoubtful) {
            // if we're showing doubtful, add it in
            $unsorted_contentious_classification_count_array["doubtful"] = $location["contentious_invalid_count"];
            $classification_count_array["doubtful"] = $location["invalid_count"];
        } else {
            // if we AREN'T showing doubtful, adjust the count
            $count -= $location["invalid_count"];
            if ($count < 1) continue;  // bail on this location if we have visible observations
        }

        $unsorted_classification_count_array  = $classification_count_array;
        arsort($classification_count_array);

        $major_classification = null;
        $minor_classification = null;

        $major_classification_count = null;
        $minor_classification_count = null;

        if ($trump) {
            // find the first trump with a positive count
            foreach($trumps as $trump) {
                if (array_key_exists($trump, $classification_count_array)) {
                    $trump_count = $classification_count_array[$trump];
                    if ($trump_count > 0) {
                        $major_classification = $trump;
                        $major_classification_count = $trump_count;
                        break; // bail once the current trump is found
                    }
                }
            }
            $minor_classification = $major_classification;

        } else { // not trumping
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
        }

        if (!$showminor) {
            $minor_classification = $major_classification;
        }

        $major_classification_properties = Vetting::getPropertiesJSONObject($major_classification);
        $minor_classification_properties = Vetting::getPropertiesJSONObject($minor_classification);

        $properties_array = array();

        $min_latitude_range  = $latitude  - (1 / ( 2 * $vet_by_rounding_to_nearest_nth_fraction) );
        $max_latitude_range  = $latitude  + (1 / ( 2 * $vet_by_rounding_to_nearest_nth_fraction) );
        $min_longitude_range = $longitude - (1 / ( 2 * $vet_by_rounding_to_nearest_nth_fraction) );
        $max_longitude_range = $longitude + (1 / ( 2 * $vet_by_rounding_to_nearest_nth_fraction) );

        $properties_array['min_latitude_range']  = $min_latitude_range;
        $properties_array['max_latitude_range']  = $max_latitude_range;
        $properties_array['min_longitude_range'] = $min_longitude_range;
        $properties_array['max_longitude_range'] = $max_longitude_range;

        // Use the vetting classification's fill color to represent the classification
        $properties_array['stroke_color'] = $major_classification_properties['fill_color'];
        $properties_array['fill_color']   = $minor_classification_properties['fill_color'];
        $properties_array['title'] = '';
        $properties_array['occurrence_type'] = 'dotgriddetail';

        $properties_array['description'] = "<div class='popupcontent'>".
                    "<dl>";

        if ( is_null($cluster_by_rounding_to_nearest_nth_fraction) ) {
            // report the lat/long, directly, if we aren't clustering
            $properties_array['description'] .=
                    "<dt>Latitude</dt><dd>$latitude</dd>".
                    "<dt>Longitude</dt><dd>$longitude</dd>";
        } else {
            // report lat/long range, if we are clustering
            $properties_array['description'] .=
                    "<dt>Latitude Range</dt><dd>".$max_latitude_range."&deg; to ".$min_latitude_range."&deg;</dd>".
                    "<dt>Longitude Range</dt><dd>".$min_longitude_range."&deg; to ".$max_longitude_range."&deg;</dd>";
        }

        $properties_array['description'] .=
                    "</dl>".
                    "<div class='table_wrapper'><table class='classifications'>".
                    "<thead><tr><th>Classification</th><th>Observations</th></tr></thead><tbody>";

        $row_count = 0;

        foreach ($unsorted_classification_count_array as $key => $value) {
            $this_contentious_count = $unsorted_contentious_classification_count_array[$key];

            if ($value > 0) {
                // only add non-zero rows
                $row_count++;
                $properties_array['description'] .=
                        "<tr class='count ".($value == 0 ? 'none' : 'some' )."'>".
                        "<td>".$key."</td>".
                        "<td>".($value == 0 ? '-' : $value)."</td></tr>".
                        ($this_contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($this_contentious_count in contention)</td></tr>");
            }
        };

//        if ($row_count > 1) {
            // only add a total row if there were more than one class rows..
            $properties_array['description'] .=
                    "<tr class='totals'><td>TOTAL</td><td>".$count."</td></tr>".($contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($contentious_count in contention)</td></tr>");
            $properties_array['description'] .=
                    "<tr class='totals'><td>TOTAL</td><td>".$count."</td></tr>".($contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($contentious_count in contention)</td></tr>");
            $properties_array['description'] .=
                    "<tr class='totals'><td>TOTAL</td><td>".$count."</td></tr>".($contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($contentious_count in contention)</td></tr>");
            $properties_array['description'] .=
                    "<tr class='totals'><td>TOTAL</td><td>".$count."</td></tr>".($contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($contentious_count in contention)</td></tr>");
            $properties_array['description'] .=
                    "<tr class='totals'><td>TOTAL</td><td>".$count."</td></tr>".($contentious_count == 0 ? '' : "<tr class='contentious'><td colspan='2'>($contentious_count in contention)</td></tr>");
//        }

        $properties_array['description'] .= "</tbody></table></div></div>";
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

