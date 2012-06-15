<?php
    require("lib/map_utility_functions.php");

    // Determine request type.
    $request_type = $_GET['REQUEST'];

    // Fill map request object based on WMS GET params.
    $map_request = ms_newOwsRequestObj();
    $map_request->loadparams();

    // Determine path to map file.
    // This dir is the map dir (contains the map files)
    $map_dir = realpath('./');

    // Determine requested map file.
    $requested_map_file = null;
    $requested_map_file = $_GET['MAP'];

    // Set full path to map file.
    $path_to_map_file = realpath($map_dir.'/'.$map_file);

    // Create a map object based on above inputs.
    $map = ms_newMapObj($path_to_map_file);
    $map->loadOWSParameters($map_request);

    // Determine input data file requested.
    $data = null;
    $data = $_GET['DATA'];

    // Get our DISTRIBUTION layer.
    $layer = $map->getLayerByName('DISTRIBUTION');
    $layer->set('data', $data);

    $threshold = null;
    // Get the threshold for this data entry
    $threshold = mu_getThreshold($map, $data);
    // Default to 0 if we couldn't determine the threshold.
    if(!is_numeric($threshold)){
        $threshold = "0";
    }

    // Pull out every class in the map file.
    mu_removeAllStyleClasses($layer);
    // Add style classes to the layer
    mu_addStyleClasses($layer, $threshold);

    $image_to_render = null;

    // Determine the image to render based on the request type.
    // Render the necessary image.
    if ($request_type === "GetMap") {
        $image_to_render = $map->draw();
    } else ($request_type === "GetLegendGraphic") {
        $image_to_render = $map->drawLegend();
    } else {
       throw new Exception('Unexpected request type. Request type was: "'.$request.'", expected GetMap or GetLegendGraphic');
    }

    // Set content type.
    header('Content-Type: image/png');
    // Output image to stdout
    $image_to_render->saveImage('');
    exit;
