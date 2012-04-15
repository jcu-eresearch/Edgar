<div class="occurrences index">
	<h2><?php echo __('Occurrences');?></h2>
	<table cellpadding="0" cellspacing="0">
	<tr>
			<th><?php echo $this->Paginator->sort('id');?></th>
			<th><?php echo $this->Paginator->sort('species_id');?></th>
			<th><?php echo $this->Paginator->sort('latitude');?></th>
			<th><?php echo $this->Paginator->sort('longitude');?></th>
			<th><?php echo $this->Paginator->sort('created');?></th>
			<th><?php echo $this->Paginator->sort('modified');?></th>
			<th class="actions"><?php echo __('Actions');?></th>
	</tr>
	<?php
	foreach ($occurrences as $occurrence): ?>
	<tr>
		<td><?php echo h($occurrence['Occurrence']['id']); ?>&nbsp;</td>
		<td>
			<?php echo $this->Html->link($occurrence['Species']['name'], array('controller' => 'species', 'action' => 'view', $occurrence['Species']['id'])); ?>
		</td>
		<td><?php echo h($occurrence['Occurrence']['latitude']); ?>&nbsp;</td>
		<td><?php echo h($occurrence['Occurrence']['longitude']); ?>&nbsp;</td>
		<td><?php echo h($occurrence['Occurrence']['created']); ?>&nbsp;</td>
		<td><?php echo h($occurrence['Occurrence']['modified']); ?>&nbsp;</td>
		<td class="actions">
			<?php echo $this->Html->link(__('View'), array('action' => 'view', $occurrence['Occurrence']['id'])); ?>
			<?php echo $this->Html->link(__('Edit'), array('action' => 'edit', $occurrence['Occurrence']['id'])); ?>
			<?php echo $this->Form->postLink(__('Delete'), array('action' => 'delete', $occurrence['Occurrence']['id']), null, __('Are you sure you want to delete # %s?', $occurrence['Occurrence']['id'])); ?>
		</td>
	</tr>
<?php endforeach; ?>
	</table>
	<p>
	<?php
	echo $this->Paginator->counter(array(
	'format' => __('Page {:page} of {:pages}, showing {:current} records out of {:count} total, starting on record {:start}, ending on {:end}')
	));
	?>	</p>

	<div class="paging">
	<?php
		echo $this->Paginator->prev('< ' . __('previous'), array(), null, array('class' => 'prev disabled'));
		echo $this->Paginator->numbers(array('separator' => ''));
		echo $this->Paginator->next(__('next') . ' >', array(), null, array('class' => 'next disabled'));
	?>
	</div>
</div>
<div class="actions">
	<h3><?php echo __('Actions'); ?></h3>
	<ul>
		<li><?php echo $this->Html->link(__('New Occurrence'), array('action' => 'add')); ?></li>
		<li><?php echo $this->Html->link(__('List Species'), array('controller' => 'species', 'action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Species'), array('controller' => 'species', 'action' => 'add')); ?> </li>
	</ul>
</div>
