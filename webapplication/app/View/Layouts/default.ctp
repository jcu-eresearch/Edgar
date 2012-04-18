<?php
/**
 *
 * PHP 5
 *
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright 2005-2012, Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright 2005-2012, Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @link          http://cakephp.org CakePHP(tm) Project
 * @package       Cake.View.Layouts
 * @since         CakePHP(tm) v 0.10.0.1076
 * @license       MIT License (http://www.opensource.org/licenses/mit-license.php)
 */

$appDescription = __d('edgar', 'INBio - Saturniidae (Lepidoptera)');
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<?php echo $this->Html->charset(); ?>
	<title>
		<?php echo $appDescription?>:
		<?php echo $title_for_layout; ?>
	</title>
	<?php
		echo $this->Html->meta('icon');

//		echo $this->Html->css('cake.generic');
		echo $this->Html->css('screen');
		echo $this->Html->css('openlayers');
		echo $this->Html->css('openlayers_extended');
		echo $this->Html->css('openlayers_google');

		// Include jQuery and jQueryUI
		echo $this->Html->script('jquery-ui-1.8.18/js/jquery-1.7.1.min.js');
		echo $this->Html->script('jquery-ui-1.8.18/js/jquery-ui-1.8.18.custom.min.js');

		// Include Google API
		echo "<script src='http://maps.google.com/maps?file=api&amp;v=2&amp;key=AIzaSyAo3TVBlAHxH57sROb2cV_7-Tar7bKnIcY'></script>";
		// echo '<script src="http://maps.google.com/maps/api/js?v=3.6&amp;sensor=false"></script>';

		// Include OpenLayers
//		echo '<script src="http://openlayers.org/api/OpenLayers.js"></script>';
		echo $this->Html->script('OpenLayers.js');
		echo $this->Html->script('LayerSwitcher-extended.js');

		echo $this->fetch('meta');
		echo $this->fetch('css');
		echo $this->fetch('script');
	?>
</head>
<body>
	<div id="container">
		<div id="header">
			<h1><?php echo $this->Html->link($appDescription, 'http://spatialecology.jcu.edu.au/CR/'); ?></h1>
		</div>
		<div id="content">

			<?php echo $this->Session->flash(); ?>

			<?php echo $this->fetch('content'); ?>
		</div>
		<div id="footer">
		</div>
	</div>
</body>
</html>
