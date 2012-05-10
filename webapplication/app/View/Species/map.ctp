<script type="text/javascript">
    <?php if($species === null): ?>
        var mapSpecies = null;
    <?php else: ?>
        var mapSpecies = <?php print json_encode($species) ?>;
    <?php endif ?>
    var mapToolBaseUrl = "http://www.hpc.jcu.edu.au/tdh-tools-2:81/map_script/";
</script>

<?php
    echo $this->Html->script(array('species_map'), array('block' => 'script'));
    echo $this->Html->script('clustering_selector_setup', array('inline'=>false));
?>

<div class="species map">
    <div class='map_legend'>
        <img id='map_legend_img' style='display:none;' src='' alt='map_legend'/>
    </div>

    <h2 style='display:none'><?php  echo __('Species Map');?></h2>

    <!-- clustering selector -->
    <fieldset class="clusteroptions" style="float: right">
        <legend>Clustering Display</legend>
        <select id="cluster">
            <option value="dotradius" >Dot Radius (no clustering)</option>
            <option value="dotgrid" selected>Dot Grid</option>
            <option value="squaregrid">Square Grid</option>
        </select>
    </fieldset>

    <table>
        <tr>
            <th>Freshness</th>
            <td id="species_freshness"></td>
        </tr>

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

    <!-- Species Selector -->
    <input id="species_autocomplete" placeholder="Type species common/scientific name here" />

    <div style="width:60em; height: 40em;" id="map"></div>
</div>
