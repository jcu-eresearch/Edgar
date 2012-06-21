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
                canVet: <?php print ($user['can_vet'] ? 'true' : 'false') ?>,
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
                if($user === NULL) {
                    // user not logged in -- show login btn
                    echo $this->Html->link('Log In', '/users/login', array('class'=>'login'));
                } else {
                    // note the user for JS usage
                    $user_js = "Edgar.user = '" . Sanitize::html($user['email']) . "'";
                    echo $this->Html->scriptBlock($user_js);
                    // write the user & logout btn into the header
                    echo 'Logged in as ' . Sanitize::html($user['email']);
                    echo $this->Html->link('Log Out', '/users/logout', array('class'=>'logout'));
                }
            ?>
        </div>
        <h1><?php echo $title_for_layout ?></h1>
    
        <ul id="tabtriggers">
            <li><a href="#" id="abouttrigger" for="about" class="closed">about Edgar</a></li>
            <li><a href="#" id="downloadstrigger" for="downloads" class="closed">downloads</a></li>
            <li><a href="#" id="abouttrigger" for="acknowledgements" class="closed">credits</a></li>
        </ul>

    </div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="downloads" class="triggeredtab"><div class="inner">
        <p class="significant">
            When completed in July 2012, Edgar will make occurrence and modelling data
            available for researchers to download.
        </p>
    </div></div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="acknowledgements" class="triggeredtab"><div class="inner">

        <div class="whitelogos">
            <?php
                echo $this->Html->image('ctbcc_logo.jpg', array(
                    'alt'=>'Centre for Tropical Biodiversity &amp; Climate Change',
                    'url'=>'http://www.jcu.edu.au/ctbcc/'
                ));
                echo $this->Html->image('tdh_logo.png', array(
                    'alt'=>'Tropical Data Hub',
                    'url'=>'http://tropicaldatahub.org/'
                ));
                echo $this->Html->image('ala_logo.jpg', array(
                    'alt'=>'Altas of Living Australia',
                    'url'=>'http://www.ala.org.au/'
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

        <p>
            Edgar is being developed by
            <a href="http://jcu-eresearch.github.com/Edgar/2012/03/22/the-team">a team</a>
            at JCU's eResearch Centre and uses data from the
            <a href="http://www.ala.org.au/">Atlas of Living Australia</a>.
            The project maintains a
            <a href="http://jcu-eresearch.github.com/Edgar/">development blog</a>
            and the source code is available on
            <a href="http://github.com/jcu-eresearch/Edgar">github</a>.
        </p><p>
            The principal researcher and project advisor is
            <a href="http://www.jjvanderwal.com/">Dr Jeremy VanDerWal</a>.
        </p><div class="additionalcontent">
            <span class="opener">Contact Dr VanDerWal</span>
            <div class="add">
                <dl>
                    <dt>on the web:</dt>
                    <dd><a href="http://www.jjvanderwal.com/">http://www.jjvanderwal.com/</a></dd>

                    <dt>by post:</dt>
                    <dd>
                        Centre for Tropical Biodiversity & Climate Change Research<br>
                        School of Marine and Tropical Biology<br>
                        James Cook University<br>
                        Townsville, QLD 4811<br>
                        Australia
                    </dd>

                    <dt>via <a href="http://www.skype.com">Skype</a>:</dt>
                    <dd><a href="skype:jjvanderwal?userinfo">jjvanderwal</a></dd>

                    <dt>via email:</dt>
                    <dd><a href="mailto:jjvanderwal@gmail.com">jjvanderwal@gmail.com</a></dd>
                </dl>
            </div>
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
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="about" class="triggeredtab"><div class="inner">
        <p class="significant">
            Edgar is a website where visitors can explore the <br>
            <strong style="white-space: nowrap">future impact</strong>
            <strong style="white-space: nowrap">of</strong>
            <strong style="white-space: nowrap">climate change</strong>
            <strong style="white-space: nowrap">on</strong>
            <strong style="white-space: nowrap">Australian birds</strong>.
        </p><p>
            This early demonstration of Edgar shows locations where a bird species has been observed,
            and displays the current climate's suitability for that species across Australia.
        </p>
        <div class="additionalcontent">
            <span class="opener">tell me more</span>
            <div class="add">
                <p>
Currently there is a general lack of engagement and knowledge transfer between professional researchers and end-users of research (general public, conservation managers, decision-makers, etc.). This is reflected in a general lack of acceptance and acknowledgement by the general public of the potential impacts of climate change. Indeed, the ABC reported 27 June 2011 that
                </p><p><cite>
“The Lowy Institute's annual poll asked about 1,000 people for their opinions ... The poll shows that there has been a steep fall in the number of Australians who think climate change is a serious problem which needs addressing now.”
                </cite></p><p>
Research individuals or groups spend considerable time and effort to bring together species occurrence data, but substantial effort is still required and limitations exist with respect to a) the accuracy of the localities, removing only blatantly incorrect records outside known locality, or b) using painstaking manual processes whereby occurrence records are presented as hardcopy maps to “species experts.”  These experts then write metadata (e.g. provenance information), corrections, and other information about further records on the maps and return the comments for interpretation. This is a cumbersome, labour-intensive, and error-prone process which needs to be repeated for each project.
                </p><p>
There is currently a scarcity of transparent online tools which integrate species distribution data, locality data with climate change scenarios in an integrated fashion which will facilitate the modelling of current and future species distributions based on climate scenarios.
                </p><p>
The Edgar site provides a tool that reuses data available with the <a href="http://www.ala.org.au/">Atlas of Living Australia</a> and the <a href="http://tropicaldatahub.org/">Tropical Data Hub</a> to allow a broad range of end-users to:
                </p><ul>
                    <li>
explore with the potential impacts of climate change on a wide range of species in Australia
                    </li><li>
engage in improving our understanding of the species and the modelling of species distributions
                    </li>
                </ul>
            </div>
        </div>
        <p>
            Edgar requires a <a href="http://browsehappy.com/">modern web browser</a> with 
            <a href="http://enable-javascript.com/">JavaScript enabled</a>.  This early
            demonstration site is unlikely to work correctly in Internet Explorer.
        </p>

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
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
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
