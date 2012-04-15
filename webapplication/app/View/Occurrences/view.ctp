<div class="occurrences view">
<h2><?php  echo __('Occurrence');?></h2>
	<dl>
		<dt><?php echo __('Id'); ?></dt>
		<dd>
			<?php echo h($occurrence['Occurrence']['id']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Species'); ?></dt>
		<dd>
			<?php echo $this->Html->link($occurrence['Species']['name'], array('controller' => 'species', 'action' => 'view', $occurrence['Species']['id'])); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Latitude'); ?></dt>
		<dd>
			<?php echo h($occurrence['Occurrence']['latitude']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Longitude'); ?></dt>
		<dd>
			<?php echo h($occurrence['Occurrence']['longitude']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Created'); ?></dt>
		<dd>
			<?php echo h($occurrence['Occurrence']['created']); ?>
			&nbsp;
		</dd>
		<dt><?php echo __('Modified'); ?></dt>
		<dd>
			<?php echo h($occurrence['Occurrence']['modified']); ?>
			&nbsp;
		</dd>
	</dl>
</div>
<div class="actions">
	<h3><?php echo __('Actions'); ?></h3>
	<ul>
		<li><?php echo $this->Html->link(__('Edit Occurrence'), array('action' => 'edit', $occurrence['Occurrence']['id'])); ?> </li>
		<li><?php echo $this->Form->postLink(__('Delete Occurrence'), array('action' => 'delete', $occurrence['Occurrence']['id']), null, __('Are you sure you want to delete # %s?', $occurrence['Occurrence']['id'])); ?> </li>
		<li><?php echo $this->Html->link(__('List Occurrences'), array('action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Occurrence'), array('action' => 'add')); ?> </li>
		<li><?php echo $this->Html->link(__('List Species'), array('controller' => 'species', 'action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Species'), array('controller' => 'species', 'action' => 'add')); ?> </li>
	</ul>
</div>
