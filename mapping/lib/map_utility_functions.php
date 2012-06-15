<?php

// Removes all style classes from the layer.
function mu_removeAllStyleClasses($layer)
{
    // Pull out every class in the map file.
    while($layer->removeClass(0) != NULL);
}

// Given a specific threshold, add the appropriate classes and associated
// styles to the layer.
function mu_addStyleClasses($layer, $threshold = "0")
{

    $layer->updateFromString(''.
        'CLASSITEM "[pixel]" '.
            'CLASS '.
                'NAME "0.0  - 0.25" '.
                'KEYIMAGE "ramp_0_25.gif" '.
                'EXPRESSION ([pixel]>'.$threshold.' AND [pixel]<0.25) '.
                'STYLE '.
                    'COLORRANGE  0 0 255 0 255 255 '.
                    'DATARANGE   0 0.25 '.
                'END '.
            'END '.
        'END');

    $layer->updateFromString(''.
        'CLASSITEM "[pixel]" '.
            'CLASS '.
                'NAME "0.25 - 0.5" '.
                'KEYIMAGE "ramp_25_50.gif" '.
                'EXPRESSION ([pixel]>'.$threshold.' AND [pixel]<0.5) '.
                'STYLE '.
                    'COLORRANGE  0 255 255 0 255 0 '.
                    'DATARANGE   0.25 0.5 '.
                'END '.
            'END '.
        'END');

    $layer->updateFromString(''.
        'CLASSITEM "[pixel]" '.
            'CLASS '.
                'NAME "0.5  - 0.75" '.
                'KEYIMAGE "ramp_50_75.gif" '.
                'EXPRESSION ([pixel]>'.$threshold.' AND [pixel]<0.75) '.
                'STYLE '.
                    'COLORRANGE  0 255 0 255 255 0 '.
                    'DATARANGE   0.5 0.75 '.
                'END '.
            'END '.
        'END');

    $layer->updateFromString(''.
        'CLASSITEM "[pixel]" '.
            'CLASS '.
                'NAME "0.75 - 1.0" '.
                'KEYIMAGE "ramp_75_100.gif" '.
                'EXPRESSION ([pixel]>'.$threshold.' AND [pixel]<=1) '.
                'STYLE '.
                    'COLORRANGE  255 255 0 255 0 0 '.
                    'DATARANGE   0.75 1 '.
                'END '.
            'END '.
        'END');

   // NOTE: Needs to go at the end, else "blanks"
   // all other style effects out.
   // I'm confident there is a much better way of injecting information
   // into the legend.
    $layer->updateFromString(''.
        'CLASSITEM "THRESHOLD" '.
            'CLASS '.
                'NAME "Threshold: '.$threshold.'" '.
                'STYLE '.
                'END '.
            'END '.
        'END');

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
