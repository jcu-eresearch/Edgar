<?php
// PHP MapScript example.
// Display a map legend as an inline image or embedded into an HTML page.
$inline = false;
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
$legend_image = $map->drawLegend();
$scale_bar_image = $map->drawScaleBar();
//$legend_image = $map->drawLegend();
if ($inline) {
    header('Content-Type: image/png');
    $map_image->saveImage('');
    exit;
}
$image_url = $map_image->saveWebImage();
$legend_image_url = $legend_image->saveWebImage();
$scale_bar_image_url = $scale_bar_image->saveWebImage();
?>
<HTML>
<HEAD>
<TITLE>PHP MapScript example: Display the legend</TITLE>
</HEAD>
<BODY>
<H2>MAP</H2>
<IMG SRC=<?php echo $image_url; ?> >
<H2>LEGEND</H2>
<IMG SRC=<?php echo $legend_image_url; ?> >
<H2>SCALE BAR</H2>
<IMG SRC=<?php echo $scale_bar_image_url; ?> >
</BODY>
</HTML>

