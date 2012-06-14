<?php
    require("lib/map_utility_functions.php");

    $map_request = ms_newOwsRequestObj();
    $map_request->loadparams();

    $map_path = realpath('./');
    $map_file = null;
    $map_file = $_GET['MAP'];

    $map = ms_newMapObj(realpath($map_path.'/'.$map_file));
    $map->loadOWSParameters($map_request);

    $data = null;
    $data = $_GET['DATA'];


    $layer = $map->getLayerByName('DISTRIBUTION');
    $threshold = $_GET['THRESHOLD'];

    if(is_numeric($threshold == false)) {
        $threshold = "0";
    }

    try {
        $shapepath = $map->shapepath;
        $datapath  = $shapepath."/".$data; 
        $data_dir  = dirname($shapepath."/".$data); 
        $maxent_results_path = $data_dir."/"."maxentResults.csv";

        $row = 1;
        $threshold_key = "Equate entropy of thresholded and original distributions logistic threshold";
        $threshold_key_pos = 0;
        $det_threshold = $threshold;
        if (($handle = fopen($maxent_results_path, "r")) !== FALSE) {
            while (($csv_data = fgetcsv($handle, 10000, ",")) !== FALSE) {
                $num = count($csv_data);
                if ($row === 1) {
                    for ($c=0; $c < $num; $c++) {
                        if ($csv_data[$c] == $threshold_key) {
                            $threshold_key_pos = $c;
                        }
                    }
                } elseif($row === 2) {
                    $det_threshold = $csv_data[$threshold_key_pos];
                }
                $row++;
            }
            fclose($handle);
        }

        if (is_numeric($det_threshold)) {
            $threshold = $det_threshold;
        }

    } catch (Exception $e) {
        // Don't do anything.
        // We only updated the threshold in the case where everything else worked.
    }


    // Pull out every class in the map file.
    mu_removeAllStyleClasses($layer);

    $layer->set('data', $data);

/*
    $layer->updateFromString(''.
        'CLASSITEM "[pixel]" '.
            'CLASS '.
                'NAME "0.0  - 0.25" '.
                'KEYIMAGE "ramp_0_25.gif" '.
                'EXPRESSION ([pixel]>'.$threshold.' AND [pixel]< 1) '.
                'STYLE '.
                    'COLORRANGE  255 255 255 255 0 0'.
                    'DATARANGE '.$threshold.' 1 '.
                'END '.
            'END '.
        'END');
        /*
*/
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

    $map_image = $map->draw();

    // Pass the map image through to view

    header('Content-Type: image/png');
    $map_image->saveImage('');
    exit;
