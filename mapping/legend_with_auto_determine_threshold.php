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

