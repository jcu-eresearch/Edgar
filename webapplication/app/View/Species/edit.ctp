<div class="species form">
<?php echo $this->Form->create('Species');?>
	<fieldset>
		<legend><?php echo __('Edit Species'); ?></legend>
	<?php
		echo $this->Form->input('id');
		echo $this->Form->input('name');
	?>
	</fieldset>
<?php echo $this->Form->end(__('Submit'));?>
</div>
<div class="actions">
	<h3><?php echo __('Actions'); ?></h3>
	<ul>

		<li><?php echo $this->Form->postLink(__('Delete'), array('action' => 'delete', $this->Form->value('Species.id')), null, __('Are you sure you want to delete # %s?', $this->Form->value('Species.id'))); ?></li>
		<li><?php echo $this->Html->link(__('List Species'), array('action' => 'index'));?></li>
		<li><?php echo $this->Html->link(__('List Occurrences'), array('controller' => 'occurrences', 'action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Occurrence'), array('controller' => 'occurrences', 'action' => 'add')); ?> </li>
	</ul>
</div>
