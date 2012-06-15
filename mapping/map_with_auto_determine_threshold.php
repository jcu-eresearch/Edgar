<?php
    require("lib/map_utility_functions.php");

    $map_request = ms_newOwsRequestObj();
    $map_request->loadparams();

    $map_path = realpath('./');
    $map_file = null;
    $map_file = $_GET['MAP'];

    $map = ms_newMapObj(realpath($map_path.'/'.$map_file));
    $map->loadOWSParameters($map_request);

    $layer = $map->getLayerByName('DISTRIBUTION');

    $data = null;
    $data = $_GET['DATA'];

    $layer->set('data', $data);

    $threshold = null;
    // Get the threshold for this data entry
    $threshold = mu_getThreshold($map, $data);
    if(is_numeric($threshold == false)) {
        $threshold = "0";
    }

    // Pull out every class in the map file.
    mu_removeAllStyleClasses($layer);

    // Add style classes to the layer
    mu_addStyleClasses($layer, $threshold);

    $map_image = $map->draw();

    // Pass the map image through to view

    header('Content-Type: image/png');
    $map_image->saveImage('');
    exit;
