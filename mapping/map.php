<?php
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
    $layer->set('data', $data);

    $map_image = $map->draw();

    // Pass the map image through to view

    header('Content-Type: image/png');
    $map_image->saveImage('');
    exit;
