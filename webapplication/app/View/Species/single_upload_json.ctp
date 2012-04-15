<div class="species upload form">
<?php echo $this->Form->create('Species', array('type'=>'file'));?>
	<fieldset>
		<legend><?php echo __('Upload Single Species'); ?></legend>
	<?php
		echo $this->Form->file('upload_file');
	?>
	</fieldset>
<?php echo $this->Form->end(__('Upload'));?>
</div>
