<?php
    // change to the fullscreen layout
    $this->layout = 'fullscreencontent';

    // build some initialising JS
    $species_value = "null";
    if ($species !== null) {
        $species_value = json_encode($species);
    }
    $species_init_js =
            "var mapSpecies = " . $species_value . ";\n"
            . 'var mapToolBaseUrl = "http://www.hpc.jcu.edu.au/tdh-tools-2:80/Edgar/mapping/";';

    // add the init JS to our scripts content block
    $this->Html->scriptBlock($species_init_js, array('inline'=>false));

    // add the actual JS that makes the map work
    $this->Html->script('species_map', array('inline'=>false));
    $this->Html->script('species_panel_setup', array('inline'=>false));
    $this->Html->script('clustering_selector_setup', array('inline'=>false));
    $this->Html->script('tabpanel_setup', array('inline'=>false));
    $this->Html->script('toolspanel_setup', array('inline'=>false));
    $this->Html->script('vetting', array('inline'=>false));

    // the init stuff needs to go early
    $this->Html->script('init_setup', array('inline'=>false, 'block'=>'earlyscript'));

?>


<div id="debugpanel" class="opposite panel debugpanel">
</div>

<div id="toolspanel" class="side panel toolspanel">

    <div id="oldvets" class="tool">
        <h1>my previous vettings</h1>
        <div class="toolcontent">
            <form id="vetlist">
                list of old vets goes here
            </form>
        </div>
    </div>

    <div id="newvet" class="tool">
        <h1>new vetting</h1>
        <div class="toolcontent">
            <div id="newvet_control" class="newvet_control">
                <button id="newvet_draw_polygon_button" class="draw_polygon">&#9997;</button>
                <button id="newvet_modify_polygon_button" class="modify_polygon">&#9988;</button>
            </div>
            <!-- new vet form -->
            <form id="vetform">
                <legend>Classification
                    <select id="vetclassification" name="classification">
                        <option value="unknown" selected>unknown</option>
                        <option value="invalid">invalid</option>
                        <option value="historic">historic</option>
                        <option value="vagrant">vagrant</option>
                        <option value="irruptive">irruptive</option>
                        <option value="non-breeding">non-breeding</option>
                        <option value="introduced non-breeding">introduced non-breeding</option>
                        <option value="breeding">breeding</option>
                        <option value="introduced breeding">introduced breeding</option>
                    </select>
                </legend>
                <legend>Comment
                    <textarea id="vetcomment" name="comment"></textarea>
                </legend>
                <button id="vet">vet</button>
            </form>
        </div>
    </div>

    <div class="tool">
        <h1>showing on the map</h1>
        <div id="layerstool" class="toolcontent"></div>
    </div>

    <div class="tool">
        <h1>some tool</h1>
        <div class="toolcontent">
            tool content goes here
        </div>
    </div>

    <div class="tool legend startclosed">
        <h1>suitability legend</h1>
        <div class="toolcontent">
            <img id='map_legend_img' style='display:none;' src='' alt='map_legend'/>
        </div>
    </div>


    <div class="tool">
        <h1>emissions and time</h1>
        <div class="toolcontent">
            <!-- the check box will probably be removed when this is working properly -->
            <input id="use_emission_and_year" type="checkbox" />
            <select id="emission_scenarios">
                <option value="sresa1b" selected="selected">sresa1b</option>
                <option value="sresb1">sresb1</option>
                <option value="sresa2">sresa2</option>
            </select>
            <select id="year_selector">
                <option value="1990">1990</option>
                <option value="2000">2000</option>
                <option value="2010">2010</option>
                <option value="2020" selected="selected">2020</option>
                <option value="2030">2030</option>
                <option value="2040">2040</option>
                <option value="2050">2050</option>
                <option value="2060">2060</option>
                <option value="2070">2070</option>
                <option value="2080">2080</option>
            </select>
        </div>
    </div>

    <div class="tool">
        <h1>debug</h1>
        <div class="toolcontent">

            <!-- clustering selector -->
            <fieldset class="clusteroptions" style="float: right">
                <legend>Clustering Display</legend>
                <select id="cluster">
                    <option value="dotradius" >Dot Radius (no clustering)</option>
                    <option value="dotgrid" selected>Dot Grid</option>
                    <option value="squaregrid">Square Grid</option>
                </select>
            </fieldset>

            <hr style="clear: both">

            <button id="go">.go.</button>
            <label><input id="done" type="checkbox" value="done" />done</label>
        </div>
    </div>

</div>

<div id="speciespanel" class="top panel speciespanel clearfix">

    <p class="minor label" id="species_modelling_status"></p>
    <p class="minor label" id="species_showing_label"></p>

    <!-- Species Selector -->
    <input id="species_autocomplete" placeholder="Type species common/scientific name here" />

    <table>
        <tr>
            <th>Modeling Status</th>
            <td>
                <span id="model_status"></span>
                <span id="model_rerun" style="display:none">
                    <a id="model_rerun_button" href="#">Boost</a>
                    <span id="model_rerun_requested">Boost successfull</span>
                </span>
            </td>
        </tr>
    </table>
</div>

<div id="map">
</div>

<div id="spinner"></div>

