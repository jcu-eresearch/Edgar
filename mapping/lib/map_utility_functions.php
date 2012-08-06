<?php

// Removes all style classes from the layer.
function mu_removeAllStyleClasses($layer)
{
    // Pull out every class in the map file.
    while($layer->removeClass(0) != NULL);
}

// Given a specific threshold, add the appropriate classes and associated
// styles to the layer.
function mu_addStyleClasses($layer, $threshold = "0", $colors = null)
{

    if ($colors === null) {
/*
        $colors = array(
            array( 0x99, 0x77, 0x00 ),     // tan
            array( 0xbb, 0xaa, 0x00 ),
            array( 0xff, 0xcc, 0x00 ),     // yellow
            array( 0x66, 0x99, 0x00 ),
            array( 0x00, 0x77, 0x00 )      // darkish green
        );
        $colors = array(
            array( 0xff, 0xcc, 0x00 ),     // yellow
            array( 0xdd, 0x99, 0x44 ),
            array( 0xcc, 0x66, 0x88 ),
            array( 0xbb, 0x33, 0xcc ),
            array( 0xaa, 0x00, 0xff )      // purple
        );
*/
        $colors = array(
            array( 0xff, 0xff, 0x00 ),     // lemon yellow
            array( 0xcc, 0xee, 0x00 ),
            array( 0x99, 0xcc, 0x00 ),
            array( 0x66, 0xbb, 0x00 ),     // mid green
            array( 0x44, 0xaa, 0x00 ),
            array( 0x22, 0x88, 0x00 ),
            array( 0x00, 0x77, 0x00 )      // green

        );
    }

    $numcolors = count($colors);
    $start = (float)$threshold;
    $range = 1.0 - $start;
    $step = (1.0 * $range) / (1.0 * $numcolors);
    $ranges = array();
    for ($i = 0; $i < $numcolors; $i++) {
        $section = array();
        $section['min'] = $start + ($i * $step);
        $section['max'] = $start + ($i * $step) + $step;
        $section['color'] = $colors[$i];
        $section['name'] = "";
        if ($i == 0) $section['name'] = '    Least Suitable';
        if ($i == $numcolors - 1) $section['name'] = '    Most Suitable';
        $ranges[] = $section;
    }

    $layer->updateFromString(''.
        'CLASSITEM "THRESHOLD" '.
            'CLASS '.
                'NAME "Threshold '.$threshold.'" '.
                'EXPRESSION (1<0) ' .
            'END '.
        'END'
    );

    foreach ($ranges as $section) {
        $layer->updateFromString(''.
            'CLASSITEM "[pixel]" '.
                'CLASS '.
                    'NAME "' . $section['name'] . '" '.
                    'EXPRESSION ([pixel]>' . $section['min'] . ' AND [pixel]<=' . $section['max'] . ') '.
                    'STYLE '.
                        'COLOR ' . implode(' ', $section['color']) . ' ' .
                    'END '.
                'END '.
            'END'
        );
    }
}

// Return the threshold, or NULL
// NULL is returned if threshold couldn't be determined.
function mu_getThreshold(
    $map, 
    $data,
    $csv_relative_path = "./maxentResults.csv",
    $csv_threshold_key = "Equate entropy of thresholded and original distributions logistic threshold"
    )
{
    try {
        // Based on the shapepath,
        // and the relative path to the data,
        // determine where the csv file with the threshold will be.

        // Get the shapepath for the map.
        $shapepath = $map->shapepath;
        // Path to data file (input map .asc file)
        $datapath  = $shapepath."/".$data; 
        // Resolve path to dir containing the data file.
        $data_dir  = dirname($shapepath."/".$data); 
        // Path to csv containing the threshold.
        $maxent_results_path = $data_dir."/".$csv_relative_path;

        // Start at row 1 (the header)
        $row = 1;
        $threshold_key_pos = null;
        $det_threshold = null;

        // open the csv for reading
        if (($handle = fopen($maxent_results_path, "r")) !== FALSE) {
            while (($csv_data = fgetcsv($handle, 10000, ",")) !== FALSE) {

                // first row (header row)
                if ($row === 1) {

                    // Iterate over the elements, looking for the position
                    // of the threshold key.
                    // Once we find the threshold key, set 
                    // threshold_key_pos and break.
                    $num = count($csv_data);
                    for ($c=0; $c < $num; $c++) {
                        // Found the key
                        if ($csv_data[$c] === $csv_threshold_key) {
                            $threshold_key_pos = $c;
                            break;
                        }
                    }

                    // Didn't find the threshold key position.
                    // Stop iterating over the csv.
                    if ($threshold_key_pos === null) {
                        break;
                    }
                } elseif($row === 2) {
                    // Found the threshold.
                    $det_threshold = $csv_data[$threshold_key_pos];
                    break;
                } else {
                    // No need to continue past first 2 rows.
                    break;
                }

                $row++;
            }
            // Close our file handle.
            fclose($handle);
        }

        // If the det_threshold is set to a good-value (numeric),
        // return it.
        if (is_numeric($det_threshold)) {
            return $det_threshold;
        } else {
        // else.. return null.
            return null;
        }

    } catch (Exception $e) {
        // Something went wrong, return null.
        return null;
    }
}

?>
