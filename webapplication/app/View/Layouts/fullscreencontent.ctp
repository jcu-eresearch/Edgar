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
App::uses('User', 'Model');
$user = AuthComponent::user();

?>
<!DOCTYPE html>
<!--[if lt IE 7]> <html class="no-js lt-ie9 lt-ie8 lt-ie7" lang="en"> <![endif]-->
<!--[if IE 7]>    <html class="no-js lt-ie9 lt-ie8" lang="en"> <![endif]-->
<!--[if IE 8]>    <html class="no-js lt-ie9" lang="en"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
<head>
    <?php echo $this->Html->charset(); ?>
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
	<meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0">

    <title><?php echo $title_for_layout; ?> - Edgar</title>

    <script type="text/javascript">
        window.Edgar = window.Edgar || {};
        Edgar.baseUrl = "<?php print $this->Html->url('/', true) ?>";
        <?php if($user === null): ?>
            Edgar.user = null;
        <?php else: ?>
            Edgar.user = {
                canRate: <?php print ($user['can_rate'] ? 'true' : 'false') ?>,
                canRequestRemodel: <?php print (User::canRequestRemodel($user) ? 'true' : 'false') ?>
            }
        <?php endif ?>
    </script>

    <link rel="stylesheet/less" type="text/css" href="<?php echo $this->Html->url('/'); ?>css/edgarfullscreen.less">

    <?php
        echo $this->Html->meta('icon');
        echo $this->Html->css('h5bp');  // html5boilerplate "sanity reset" css
        echo $this->Html->css('edgar');
//        echo $this->Html->css('edgarfullscreen');
        echo $this->Html->css('../js/jquery-ui-1.8.18/css/smoothness/jquery-ui-1.8.18.custom');
        echo $this->Html->css('openlayers');
        echo $this->Html->css('openlayers_extended');
        echo $this->Html->css('openlayers_google');

        // include Modernizr for html5 shims and feature detection.  this needs to go early!
    	$this->Html->script('modernizr/modernizr-2.5.3.min.js', array('block'=>'earlyscript', 'inline' => false));
        $this->Html->script('less-1.3.0.min.js', array('inline' => false, 'block'=>'earlyscript'));


        // Include jQuery and jQueryUI
        $this->Html->script('jquery-ui-1.8.18/js/jquery-1.7.1.min.js', array('inline' => false, 'block'=>'libscript'));
        $this->Html->script('jquery-ui-1.8.18/js/jquery-ui-1.8.18.custom.min.js', array('inline' => false, 'block'=>'libscript'));
        $this->Html->script('history.js/scripts/bundled/html4+html5/jquery.history.js', array('inline' => false, 'block'=>'libscript'));
        $this->append('libscript');
            // Include Google API
            // Note: API Key is Robert's.
            echo "<script src='http://maps.google.com/maps?file=api&amp;v=2&amp;key=AIzaSyAo3TVBlAHxH57sROb2cV_7-Tar7bKnIcY'></script>";
        $this->end();
        // Include OpenLayers
        $this->Html->script('OpenLayers.js', array('inline' => false, 'block'=>'libscript'));
        $this->Html->script('LayerSwitcher-extended.js', array('inline' => false, 'block'=>'libscript'));

        // now emit the meta, css and *some* js tags
        echo $this->fetch('meta');
        echo $this->fetch('css');
        echo $this->fetch('earlyscript');
    ?>

</head>
<body>

    <div id="header">
        <div id="user">
            <?php
                $user = AuthComponent::user();
                if($user === NULL){
                    echo $this->Html->link('Log In', '/users/login', array('class'=>'login'));
                } else {
                    echo 'Logged in as ' . Sanitize::html($user['email']);
                    echo $this->Html->link('Log Out', '/users/logout', array('class'=>'logout'));
                }
            ?>
        </div>
        <h1><?php echo $title_for_layout ?></h1>
    
        <ul id="tabtriggers">
            <li><a href="#" id="abouttrigger" for="about" class="closed">about Edgar</a></li>
            <li><a href="#" id="downloadstrigger" for="downloads" class="closed">downloads</a></li>
            <li><a href="#" id="abouttrigger" for="acknowledgements" class="closed">acknowledgements</a></li>
        </ul>

    </div>

    <div id="about" class="triggeredtab"><div class="inner">
        <p class="significant">
            Edgar is a website where visitors can explore the <strong style="white-space: nowrap">future impact of climate change on Australian birds</strong>.
        </p><p>
            This early demonstration of Edgar shows locations where a bird species has been observed,
            and displays the current climate's suitability for that species across Australia.
        </p>
        <div class="additionalcontent">
            <span class="opener">tell me more</span>
            <div class="add">
                <p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p><p>
                stuff
                </p>
            </div>
        </div>

        <p>
            Edgar requires a <a href="http://browsehappy.com/">modern web browser</a> with 
            <a href="http://enable-javascript.com/">JavaScript enabled</a>.  This early
            demonstration site is unlikely to work correctly in Internet Explorer.
        </p>

    </div></div>

    <div id="downloads" class="triggeredtab"><div class="inner">
        <p class="significant">
            When completed in July 2012, Edgar will make occurrence and modelling data
            available for researchers to download.
        </p>
    </div></div>

    <div id="acknowledgements" class="triggeredtab"><div class="inner">

        <div class="whitelogos">
            <?php
                echo $this->Html->image('ctbcc_logo.jpg', array(
                    'alt'=>'Centre for Tropical Biodiversity &amp; Climate Change',
                    'url'=>'http://www.jcu.edu.au/ctbcc/'
                ));
                echo $this->Html->image('jcu_logo.png', array(
                    'alt'=>'James Cook University',
                    'url'=>'http://www.jcu.edu.au/'
                ));
                echo $this->Html->image('eresearch_logo.png', array(
                    'alt'=>'JCU eResearch Centre',
                    'url'=>'http://eresearch.jcu.edu.au/'
                ));
            ?>
        </div>

        <div class="funding clearfix">
            <?php
                echo $this->Html->image('ands_logo.jpg', array(
                    'alt'=>'Australian National Data Service',
                    'url'=>'http://www.ands.org.au/',
                    'class'=>'goleft'
                ));
                echo $this->Html->image('qcif_logo.png', array(
                    'alt'=>'Queensland Cyber Infrastructure Foundation',
                    'url'=>'http://www.qcif.edu.au/'
                ));
            ?>

            This project is supported by the 
            <a href="http://www.ands.org.au/">Australian National Data Service (ANDS)</a>
            through the National Collaborative Research Infrastructure Strategy Program and the
            Education Investment Fund (EIF) Super Science Initiative, as well as through the
            <a href="http://www.qcif.edu.au/">Queensland Cyber Infrastructure Foundation (QCIF)</a>
        </div>
    </div></div>

    <div id="content">
        <?php echo $this->fetch('content') ?>
    </div>

    <div id="sidebar">

        <div id="flash">
            <div class="wrapper">
                <?php echo $this->Session->flash() ?>
            </div>
        </div>

        <div id="footer">
        </div>
    
    </div>

    <?php
        echo $this->element('sql_dump');
        echo $this->fetch('libscript');
        echo $this->fetch('script');
    ?>
</body>
</html>
