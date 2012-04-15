<?php
	// Inject javascript to specify species_id and map_tool_url.
	$map_tool_url = $this->Html->url(array("controller" => "tools", "action" => "map"));
	$code_block =  "var species_id = '".$species['Species']['id']."';\n".
	               "var map_tool_url = '".$map_tool_url."';";
	echo $this->Html->scriptBlock($code_block, array('block' => 'script')); 

	// Include map javascript files
	echo $this->Html->script(array('species_map'), array('block' => 'script')); 
?>

<div class="species map">
<h2><?php  echo __('Species');?></h2>
	<dl>
		<dt><?php echo __('Id'); ?></dt>
		<dd>
			<?php echo h($species['Species']['id']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Name'); ?></dt>
		<dd>
			<?php echo h($species['Species']['name']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Created'); ?></dt>
		<dd>
			<?php echo h($species['Species']['created']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Modified'); ?></dt>
		<dd>
			<?php echo h($species['Species']['modified']); ?>
			&nbsp;
		</dd>
	</dl>
	<div style="width:60em; height: 40em;" id="map"></div>
</div>
