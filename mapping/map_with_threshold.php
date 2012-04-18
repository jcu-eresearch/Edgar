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
    $threshold = $_GET['THRESHOLD'];

    # Pull out every class in the map file.
    while($layer->removeClass(0) != NULL);

    $layer->set('data', $data);
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
                'NAME "0.75 - 1" '.
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
