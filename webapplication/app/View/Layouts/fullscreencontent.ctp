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
                isAdmin: <?php print ($user['is_admin'] ? 'true' : 'false') ?>,
                canRequestRemodel: <?php print (User::canRequestRemodel($user) ? 'true' : 'false') ?>,
                id: "<?php print Sanitize::html($user['id']) ?>",
                email: "<?php print Sanitize::html($user['email']) ?>"
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
        $this->Html->script('json2.js', array('inline' => false));
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
        <a href="<?php print $this->Html->url('/'); ?>">
            <img id="edgar-logo" src="<?php print $this->Html->url('/img/edgarlogo41.png'); ?>" />
        </a>

        <div id="user">
            <?php
                $user = AuthComponent::user();
                if($user === NULL) {
                    // user not logged in -- show login btn
                    echo $this->Html->link('Log In', '/users/login', array('class'=>'login'));
                } else {
                    // note the user for JS usage
                    //$user_js = "Edgar.user = '" . Sanitize::html($user['email']) . "'";
                    //echo $this->Html->scriptBlock($user_js);
                    // write the user & logout btn into the header
                    echo 'Logged in as ' . Sanitize::html($user['email']);
                    echo $this->Html->link('Log Out', '/users/logout', array('class'=>'logout'));
                }
            ?>
        </div>
        <h1><?php echo $title_for_layout ?></h1>
    
        <ul id="tabtriggers">
            <li><a href="#" id="abouttrigger" for="about" class="closed">about</a></li>
            <li><a href="#" id="sciencetrigger" for="science" class="closed">the science</a></li>
            <li><a href="#" id="howtotrigger" for="howto" class="closed">using Edgar</a></li>
            <li><a href="#" id="glossarytrigger" for="glossary" class="closed">glossary</a></li>
            <li><a href="#" id="abouttrigger" for="acknowledgements" class="closed">credits</a></li>
            <?php if(AuthComponent::user('is_admin')): ?>
                <li><a href="#" id="admintrigger" for="admin" class="closed">admin</a></li>
            <?php endif ?>
        </ul>

    </div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="science" class="triggeredtab"><div class="inner">
        <p>
Edgar uses the 
<a href="http://www.ala.org.au/">Atlas of Living Australia</a>
bird observation database to generate current and future species distribution models.  These are built for each of 4 Representative Concentration Pathways (RCPs, which are analogous to carbon emission scenarios) using the median of 18 global climate models (GCMs), and 8 time steps between 2015 and 2085.
        </p><div class="additionalcontent">
            <span class="opener">Preparing observation records for modelling</span>
            <div class="add"><p>
                Bird observation records retrieved from the
                <a href="http://www.ala.org.au/">Atlas of Living Australia</a>'s (ALA) database have been filtered based on ALA's 'assertions' and those inappropriate for modelling were excluded. Additionally,
                <a href="http://www.birdlife.org.au/">BirdLife Australia</a>
                provided species range information, against which we check each observation to obtain an initial classification as core habitat, introduced, historic, vagrant, irruptive, or doubtful. Observation records that fall outside these ranges are marked as unclassified, and are assumed to be valid for modelling.
            </p><p>
                This initial classification for observations is compared against classifications collected from
                birdwatchers and other knowledgeable visitors to the Edgar site.  Edgar tracks contentious records, but generally a vetting entered by a logged-in site user will be considered accurate and changes
                the derived classification of an observation.
            </p><p>
                Doubtful records and records that are considered historic, irruptive, or vagrant are not used to model climate suitability for a species.  Only species with &gt;20 unique location records are modeled.
            </p></div>
        </div><div class="additionalcontent">
            <span class="opener">Acquiring and generating current and future climate data</span>
            <div class="add"><p>
                We used climate data from the
                <a href="http://www.bom.gov.au/jsp/awap/">Australian Water Availability Project</a>
                (AWAP) to caculate important climate variables such as current annual mean temperature, temperature seasonality, and annual precipitation. We generated projected values for those variables using all 18 global climate models (GCMs) for all RCP scenarios (RCP2.6, RCP4.5, RCP6, RCP8.5) at 8 time steps between 2015 and 2085.
            </p></div>
        </div><div class="additionalcontent">
            <span class="opener">Generating climate suitability maps</span>
            <div class="add"><p>
                Species distribution models are generated dynamically using the presence-only modelling program
                <a href="http://www.cs.princeton.edu/~schapire/maxent/">Maxent</a> (Phillips et al 2006). Maxent uses species presence records to statistically relate species occurrence to environmental variables on the principle of maximum entropy.
            </p><p>
                Edgar continues to collect new observations from ALA and new vettings from site visitors, and as species observations are changed and refined, Edgar regenerates the species' climate maps using the new data. The most up-to-date maps of climate suitability are displayed on Edgar.
            </p></div>
        </div>

    </div></div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="glossary" class="triggeredtab"><div class="inner">
		
        <div class="additionalcontent">
            <span class="opener">Observation Classifications</span>
            <div class="add"><dl>
                <dt>
                    Unclassified
                </dt><dd>Observation records that have not been
    classified within any other category.  With nothing else to go on, these records are assumed to be
    valid and are included in the modelling.  Please improve future models
    by classifying these records!
                </dd><dt>
                    Core
                </dt><dd>An observation record that falls within any area essential to
    survival of the species.  This includes breeding grounds, stop-off
    points for migratory birds, and locations that are visited seasonally.
                </dd><dt>
                    Historic
                </dt><dd>The species has not been observed at this location since
    1975.  We use the cutoff date of 1975 because climate change is
    underway, and this is reflected in species distribution changes.  If a
    bird species has not been observed at a location since 1975, we cannot
    assume that the climate at that location has remained suitable for the
    species.
                </dd><dt>
                    Irruptive
                </dt><dd>Observations at a location represent a dramatic, irregular
    migration of many birds away from their core range.  These irruptions
    may occur in cycles over many years, or they may be much more
    unpredictable.
                </dd><dt>
                    Vagrant
                </dt><dd>Individuals of a species have appeared well outside their
    core range.  Escapees that have not established a population are
    included within this definition on this site.
                </dd><dt>
                    Introduced
                </dt><dd>A native or non-native species has established a
    population within an area well outside their native core range.
                </dd><dt>
                    Doubtful
                </dt><dd>It is very unlikely that this species was observed at this location.
                </dd>
            </dl></div>
        </div>
		
		<div class="additionalcontent">
            <span class="opener">Emission Pathways: RCPs</span>
            <div class="add">
				<p>
					RCP stands for <a href="http://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=welcome#descript" target="_blank">Representative Concentration Pathway</a>.  The RCPs are not new, fully integrated scenarios (i.e., they are not a complete package of socioeconomic, emissions, and climate projections). They are consistent sets of projections of only the components of radiative forcing that are meant to serve as input for climate modelling, pattern scaling, and atmospheric chemistry modeling.  Here, we have used <a href="http://wallaceinitiative.org/climate_2012/tdhtools/Search/DataDownload.php" target="_blank">climate layers</a> developed by Jeremy VanDerWal that have been derived from the following RCPs:
				</p><dl>
					<dt>
						RCP2.6
					</dt><dd>
						The <a href="http://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=welcome#rcpinfo" target="_blank">RCP2.6</a> emission pathway is representative for scenarios leading to very low greenhouse gas concentration levels: peak in radiative forcing at ~ 3 W/m2 before 2100 and decline.
					</dd>
					<dd>
						Mean temperature increase for Australia: 0.91 degrees by 2085
					</dd><dt>
						RCP4.5
					</dt><dd>
						The <a href="http://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=welcome#rcpinfo" target="_blank">RCP4.5</a> emission pathway It is a stabilization scenario : stabilization without overshoot pathway to 4.5 W/m2 at stabilization after 2100.
					</dd><dd>
						Mean temperature increase for Australia: 1.83 degrees by 2085
					</dd><dt>
						RCP6
					</dt><dd>
						The <a href="http://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=welcome#rcpinfo" target="_blank">RCP6</a> emission pathway is a stabilization scenario : stabilization without overshoot pathway to 6 W/m2 at stabilization after 2100.
					</dd><dd>
						Mean temperature increase for Australia: 2.29 degrees by 2085
					</dd><dt>
						RCP8.5
					</dt><dd>
						The <a href="http://www.iiasa.ac.at/web-apps/tnt/RcpDb/dsd?Action=htmlpage&page=welcome#rcpinfo" target="_blank">RCP8.5</a> is characterized by increasing greenhouse gas emissions over time: rising radiative forcing pathway leading to 8.5 W/m2 in 2100. 
					</dd><dd>
						Mean temperature increase for Australia: 3.78 degrees by 2085
					</dd>
				</dl>
			</div>
		</div>
		
    </div></div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="howto" class="triggeredtab"><div class="inner">
        <div class="additionalcontent">
            <span class="opener">Introduction</span>
            <div class="add"><p>
Edgar performs three roles:
                </p><ol>
                    <li>show observation records and current climate suitability for a species</li>
                    <li>show future climate suitability</li>
                    <li>vet observation records.</li>
                </ol><p>
                </p>
            </div>
        </div>
        <div class="additionalcontent">
            <span class="opener">Viewing observations and current climate suitability</span>
            <div class="add"><p>
Edgar starts by showing you a search box across the top of a map.
If you are alreadying viewing a species, you can switch back to the search box
species by clicking the 'change species' button near the species name.
            </p><p>
Type a species of your choice into the search box.  As you type Edgar will 
pop up a list suggesting matching species; when you see the species you are
looking for, click its name (or use your arrow and Enter keys to select it).
            </p><p>
While viewing a species, bird observations are clustered so that a single
coloured "dot" summaries the observations across an area.  A cluster dot
is drawn larger to represent a high number of observations in that area,
and smaller to represent fewer observations.
            </p><p>
As you zoom into an area, cluster dots are re-drawn so that each dot 
covers a smaller area.  When you zoom in far enough, observations 
un-cluster to represent the recorded location of bird sightings.
            </p></div>
        </div><div class="additionalcontent">
            <span class="opener">Viewing future climate suitability</span>
            <div class="add"><p>
Select the species as described above, then click the "see future projections"
button near the top right corner of your map.  Edgar will show you a new set of
tools down the right side of your screen, and start loading map projections.
This will take a few seconds, or longer on slower internet connections.
            </p><p>
Once the future climate suitability maps have loaded, click the
green-circled play button to watch how the suitability will shift
into the future.  You can also drag the slider to examine any modelled year
from 2015 to 2085 in ten year steps.
            </p><p>
You can view future climate suitability under an alternative emission scenario
by selecting the scenario in the right column.
            </p></div>
        </div><div class="additionalcontent">
            <span class="opener">Vetting observation records</span>
            <div class="add"><p>
To vet observation records, you will need a user account.  To help reduce the
number of logins you might need to create and remember, Edgar shares the user
account system from the <a href="https://www.ala.org.au/">Atlas of Living Australia</a>.
            </p><p>
Click the 'Log In' button at the top right corner of the screen.  This
will take you to the Atlas of Living Australia (ALA) website.  If you
already have a username and password, log in; if you do not, click the
registration link to register.  Registration with ALA only requires
your name or alias, and a valid email address.
            </p><p>
Once logged in to ALA, you will be returned to the Edgar site.  Enter the
species you would like to vet into the search box, then click the
'vet this species' at the top of the right tool bar. Edgar will show you a
 new set of tools down the right side of your screen, including a 
 'vet observations' tool below the classification legend.
            </p><p>
Recording a vetting is a three step process:
            </p><dl>
                <dt>Step 1: select observations</dt>
                <dd>
To record a vetting, click 'Select Observations' and either:
                    <ul>
                        <li>click an observation or cluster of observations, or</li>
                        <li>click-and-drag a selection box over multiple observations or clusters.</li>
                    </ul>
                </dd><dd>
Selected areas will be highlighted with orange boxes.
To de-select these areas, click 'Clear Selection', then choose
'Select Observations' to start again.
                </dd><dd>
Note: You can select multiple areas across Australia and give all 
selected areas a single classification.  For example, you might wish
to classify multiple records offshore or in the central desert as
'doubtful'.
                </dd>
                <dt>Step 2: enter your opinion</dt>
                <dd>
Having selected the observations you want to re-classify, choose a 
new classification from the drop-down menu in the 'vet observations' toolbox.
You may add details about your reasons for your classification choice if you
like.
                </dd>
                <dt>Step 3: save</dt>
                <dd>
Finally, click 'Save this Vetting' to apply your classification.  A confirmation popup will appear and the selected
area will be highlighted according to the classification you provided.
                </dd>
            </dl><p>
When you have finished vetting one species, you can begin vetting
another species by clicking 'Change species'.
            </p></div>
        </div>

        <div class="additionalcontent">
            <span class="opener">Frequently Asked Questions</span>
            <div class="add"><dl>

                <dt>
Why can't I find the species I'm interested in?
                </dt><dd>
We filter the species list to only include species for which we have observations.  It's possible that the Atlas of Living Australia has no observation records for the species you're looking for. 
                </dd>
 
				<dt>
Why are there no records for this species?
                </dt><dd>
We display all bird observation records retrieved from ALA so that we can classify those records and send that classification back to ALA.  If no records are shown for a species, it means that all records for that species have been classified as 'doubtful'.  If you wish to see the doubtful records, register an account with <a href="http://www.ala.org.au" target="_blank">ALA</a> and log in to Edgar.  You may then see and vet the records.
                </dd>
				
				<dt>
Why is there no climate suitability map for some species? (ie. Why has a species not been modelled?)
                </dt><dd>
We can only model species that have 20 or more observations at unique locations at a 5km resolution.
                </dd>
				
				<dt>
How do I obtain accurate observation records for a species?
                </dt><dd>
Most data available for download on Edgar is accurate, however some location observations for some species are considered sensitive information and we cannot release it either visually (displayed on the map), or as downloadable data.  If you require accurate observation records for a species, contact <a href="http://www.ala.org.au" target="_blank">ALA</a>.
                </dd>
				
                <dt>
How do I report a bug/suggest a new feature for Edgar?
                </dt><dd>
Email <a href="mailto:jjvanderwal@gmail.com">Jeremy VanDerWal</a>.
                </dd>

                <dt>
Can I use Edgar / Edgar's data / pictures from Edgar / text from Edgar in my project?
                </dt><dd>
Edgar's source code is released under a <a href="http://tropicaldatahub.org/apps/edgar/license">BSD-style licence</a> and available from <a href="https://github.com/jcu-eresearch/Edgar">github</a>.
                </dd><dd>
Edgar's content, including Edgar's documentation, is licenced using <a href="http://creativecommons.org/licenses/by/3.0/au/">CC-BY</a>, which essentially means you can do whatever you like with Edgar's data, as long as you credit it properly.
                </dd>

            </dl></div>
        </div>

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
                    'url'=>'http://tropicaldatahub.org/',
					'class' => 'unpaddedlogo'
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
                    'url'=>'http://eresearch.jcu.edu.au/',
					'class' => 'unpaddedlogo'
                ));
            ?>
        </div>

        <p>
            Edgar was developed by
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

            This project was supported by the 
            <a href="http://www.ands.org.au/">Australian National Data Service (ANDS)</a>
            through the National Collaborative Research Infrastructure Strategy Program and the
            Education Investment Fund (EIF) Super Science Initiative, as well as through the
            <a href="http://www.qcif.edu.au/">Queensland Cyber Infrastructure Foundation (QCIF)</a>
        </div>
    </div></div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <div id="about" class="triggeredtab"><div class="inner">
        <p class="very significant">
            Edgar is a website where visitors can explore the <br>
            <strong style="white-space: nowrap">future impact</strong>
            <strong style="white-space: nowrap">of</strong>
            <strong style="white-space: nowrap">climate change</strong>
            <strong style="white-space: nowrap">on</strong>
            <strong style="white-space: nowrap">Australian birds</strong>.
        </p><p class="significant">
            Birdwatchers and other experts can
            <strong>improve the accuracy</strong>
            of Edgar's projections by classifying observations.
        </p><p>
            Edgar shows locations where a bird species has been observed 
            and uses this information to calculate and display how well
            the climate the climate across Australia suits that species.
        </p><p>
            Edgar can also show an animation of how the suitable climate
            for a species may change into the future.
        </p>
        <div class="additionalcontent">
            <span class="opener">tell me more</span>
            <div class="add">
                <p>
Currently there is a general lack of engagement and knowledge transfer between professional researchers and end-users of research (general public, conservation managers, decision-makers, etc.). This is reflected in a general lack of acceptance and acknowledgement by the general public of the potential impacts of climate change. Indeed, the ABC reported 27 June 2011 that
                </p><p><cite>
"The Lowy Institute's annual poll asked about 1,000 people for their opinions ... The poll shows that there has been a steep fall in the number of Australians who think climate change is a serious problem which needs addressing now."
                </cite></p><p>
Research individuals or groups spend considerable time and effort to bring together species occurrence data, but substantial effort is still required and limitations exist with respect to a) the accuracy of the localities, removing only blatantly incorrect records outside known locality, or b) using painstaking manual processes whereby occurrence records are presented as hardcopy maps to "species experts."  These experts then write metadata (e.g. provenance information), corrections, and other information about further records on the maps and return the comments for interpretation. This is a cumbersome, labour-intensive, and error-prone process which needs to be repeated for each project.
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
            <a href="http://enable-javascript.com/">JavaScript enabled</a>.  If you are using
            an older version of Microsoft Internet Explorer, the
            <a href="http://www.google.com/chromeframe">Chrome Frame</a>
            plug-in from Google can significantly improve your experience of this site.
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

            <div class="cc-by">
                <a rel="license" href="http://creativecommons.org/licenses/by/3.0/au/"><img alt="Creative Commons License" id="cc-logo" src="http://i.creativecommons.org/l/by/3.0/au/88x31.png" /></a>
                This <span xmlns:dct="http://purl.org/dc/terms/" href="http://purl.org/dc/dcmitype/Text" rel="dct:type">site</span> by the <a xmlns:cc="http://creativecommons.org/ns#" href="http://www.jcu.edu.au/ctbcc/" property="cc:attributionName" rel="cc:attributionURL">Centre for Tropical Biodiversity &amp; Climate Change</a> and the <a xmlns:cc="http://creativecommons.org/ns#" href="http://eresearch.jcu.edu.au" property="cc:attributionName" rel="cc:attributionURL">eResearch Centre</a>, <a href="http://www.jcu.edu.au">James Cook University</a> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/3.0/au/">Creative Commons Attribution 3.0 Australia License</a>.
            </div>
        </div>
    </div></div>
    <!-- = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = -->
    <?php if(AuthComponent::user('is_admin')): ?>
        <div id="admin" class="triggeredtab"><div class="inner">
            <ul>
                <li><?php print $this->Html->link('Contentious Species', '/admin') ?></li>
            </ul>
        </div></div>
    <?php endif ?>
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
