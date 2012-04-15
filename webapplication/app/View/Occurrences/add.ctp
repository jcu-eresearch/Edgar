<div class="occurrences form">
<?php echo $this->Form->create('Occurrence');?>
	<fieldset>
		<legend><?php echo __('Add Occurrence'); ?></legend>
	<?php
		echo $this->Form->input('species_id');
		echo $this->Form->input('latitude');
		echo $this->Form->input('longitude');
	?>
	</fieldset>
<?php echo $this->Form->end(__('Submit'));?>
</div>
<div class="actions">
	<h3><?php echo __('Actions'); ?></h3>
	<ul>

		<li><?php echo $this->Html->link(__('List Occurrences'), array('action' => 'index'));?></li>
		<li><?php echo $this->Html->link(__('List Species'), array('controller' => 'species', 'action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Species'), array('controller' => 'species', 'action' => 'add')); ?> </li>
	</ul>
</div>
