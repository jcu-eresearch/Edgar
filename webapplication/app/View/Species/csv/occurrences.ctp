<?php
echo "SPPCODE, LATDEC, LONGDEC\n";

foreach ($species['Occurrence'] as $occurrence):
	echo $species['Species']['id'].", ".$occurrence['latitude'].", ".$occurrence['longitude']."\n";
endforeach;
