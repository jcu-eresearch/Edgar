<?php
// PHP MapScript example.
// Display a map legend as an inline image or embedded into an HTML page.
$inline = true;
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

$threshold = $_GET['THRESHOLD'];

# Add the threshold info to the legend
$layer->updateFromString(''.
    'CLASSITEM "THRESHOLD" '.
        'CLASS '.
            'NAME "Threshold: '.$threshold.'" '.
            'STYLE '.
            'END '.
        'END '.
    'END');

$map_image = $map->draw();
$legend_image = $map->drawLegend();
//$legend_image = $map->drawLegend();
if ($inline) {
    header('Content-Type: image/png');
    $legend_image->saveImage('');
    exit;
}
$legend_image_url = $legend_image->saveWebImage();
?>
<HTML>
<HEAD>
<TITLE>PHP MapScript example: Display the legend</TITLE>
</HEAD>
<BODY>
<H2>LEGEND</H2>
<IMG SRC=<?php echo $legend_image_url; ?> >
</BODY>
</HTML>

