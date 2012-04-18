<?php
    // Inject javascript to specify species_id and map_tool_url.
//    $map_tool_url = $this->Html->url(array("controller" => "tools", "action" => "map"));
    $map_tool_base_url = "http://www.hpc.jcu.edu.au/tdh-tools-2:81/map_script/";
    $species_route_url = $this->Html->url(array("controller" => "species", "action" => "index"));
    if ($single_species_map) {
        $species_sci_name_cased = $species['Species']['scientific_name'];
        // Remove dots
        $species_sci_name_cased = preg_replace('/(\.)/', '', $species_sci_name_cased);
        // Remove leading and trailing space.
        $species_sci_name_cased = preg_replace('/(\s+)$/', '', $species_sci_name_cased);
        $species_sci_name_cased = preg_replace('/^(\s+)/', '', $species_sci_name_cased);
        // Replace remaining spaces with _
        $species_sci_name_cased = preg_replace('/(\s)/', '_', $species_sci_name_cased);

        $code_block =  "var species_id = '".$species['Species']['id']."';\n".
                       "var map_tool_base_url = '".$map_tool_base_url."';".
                       "var species_route_url= '".$species_route_url."';".
                       "var species_sci_name_cased = '".$species_sci_name_cased."';";
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
    } else {
        $code_block =  "var species_id = undefined;".
                       "var map_tool_base_url = '".$map_tool_base_url."';".
                       "var species_route_url= '".$species_route_url."';";
        // Include map javascript files
        echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 
        echo $this->Html->script(array('species_map'), array('block' => 'script')); 
    }

?>

<div class="species map">
    <div class='map_legend'>
        <img id='map_legend_img' style='display:none;' src='' alt='map_legend'/>
    </div>

<?php
    if ($single_species_map) {
?>
<h2><?php  echo __('Species Map');?></h2>
<!-- Map Specific For Species -->
    <dl>
        <dt><?php echo __('Id'); ?></dt>
        <dd>
            <?php echo h($species['Species']['id']); ?>
            &nbsp;
        </dd>
        <dt><?php echo __('Scientific Name'); ?></dt>
        <dd>
            <?php echo h($species['Species']['scientific_name']); ?>
            &nbsp;
        </dd>
        <dt><?php echo __('Common Name'); ?></dt>
        <dd>
            <?php echo h($species['Species']['common_name']); ?>
            &nbsp;
        </dd>
    </dl>

<?php
    } else {
?>
    <h2 style='display:none'><?php  echo __('Species Map');?></h2>
    <!-- Species Selector -->
    <?php
        echo $this->Form->create('Species', array(
            'type' => 'get',
            'action' => 'map'
        ));
    ?>
        <?php
            echo $this->Form->input('species_id', array('empty' => '(choose one)'));
        ?>
    <?php echo $this->Form->end();?>
<?php
    }
?>
    <div style="width:60em; height: 40em;" id="map"></div>
</div>
