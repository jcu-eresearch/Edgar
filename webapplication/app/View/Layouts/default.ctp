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

App::uses('Sanitize', 'Utility');

?>
<!DOCTYPE html>
<html>
    <head>
        <?php echo $this->Html->charset(); ?>
        <title><?php echo $title_for_layout; ?> - Edgar</title>

        <script type="text/javascript">
            window.Edgar = window.Edgar || {};
            Edgar.baseUrl = "<?php print $this->Html->url('', true) ?>";
        </script>

        <?php
            echo $this->Html->meta('icon');
            echo $this->Html->css('edgar');
            echo $this->Html->css('../js/jquery-ui-1.8.18/css/smoothness/jquery-ui-1.8.18.custom');
            echo $this->Html->css('openlayers');
            echo $this->Html->css('openlayers_extended');
            echo $this->Html->css('openlayers_google');


            // Include jQuery and jQueryUI
            echo $this->Html->script('jquery-ui-1.8.18/js/jquery-1.7.1.min.js');
            echo $this->Html->script('jquery-ui-1.8.18/js/jquery-ui-1.8.18.custom.min.js');

            // Include Google API
            // Note: API Key is Robert's.
            echo "<script src='http://maps.google.com/maps?file=api&amp;v=2&amp;key=AIzaSyAo3TVBlAHxH57sROb2cV_7-Tar7bKnIcY'></script>";

            // Include OpenLayers
            echo $this->Html->script('OpenLayers.js');
            echo $this->Html->script('LayerSwitcher-extended.js');

            echo $this->fetch('meta');
            echo $this->fetch('css');
            echo $this->fetch('script');
        ?>
    </head>
    <body>
        <div id="header">
            <div class="wrapper">
                <img src="<?php print $this->Html->url('/img/logo.png') ?>" />
                <div class="login"><?php
                    $user = AuthComponent::user();
                    if($user === NULL){
                        print $this->Html->link('Log In', '/users/login');
                    } else {
                        print 'Logged in as ' . Sanitize::html($user['email']) . ' (';
                        print $this->Html->link('Log Out', '/users/logout');
                        print ')';
                    }
                ?></div>

            </div>
        </div>

        <div id="content">
            <div class="wrapper">
                <?php echo $this->Session->flash() ?>
                <h1><?php echo $title_for_layout ?></h1>
                <?php echo $this->fetch('content') ?>
            </div>
        </div>

        <div id="footer">
        </div>
        <?php echo $this->element('sql_dump'); ?>
    </body>
</html>
