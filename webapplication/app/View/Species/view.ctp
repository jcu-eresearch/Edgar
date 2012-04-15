<div class="species view">
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
</div>
<div class="actions">
	<h3><?php echo __('Actions'); ?></h3>
	<ul>
		<li><?php echo $this->Html->link(__('Species Map'), array('action' => 'map', $species['Species']['id'])); ?> </li>
		<li><?php echo $this->Html->link(__('Edit Species'), array('action' => 'edit', $species['Species']['id'])); ?> </li>
		<li><?php echo $this->Form->postLink(__('Delete Species'), array('action' => 'delete', $species['Species']['id']), null, __('Are you sure you want to delete # %s?', $species['Species']['id'])); ?> </li>
		<li><?php echo $this->Html->link(__('List Species'), array('action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Species'), array('action' => 'add')); ?> </li>
		<li><?php echo $this->Html->link(__('List Occurrences'), array('controller' => 'occurrences', 'action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('New Occurrence'), array('controller' => 'occurrences', 'action' => 'add')); ?> </li>
	</ul>
</div>
<div class="related">
	<h3><?php echo __('Related Occurrences');?></h3>
	<?php if (!empty($species['Occurrence'])):?>
	<table cellpadding = "0" cellspacing = "0">
	<tr>
		<th><?php echo __('Id'); ?></th>
		<th><?php echo __('Species Id'); ?></th>
		<th><?php echo __('Latitude'); ?></th>
		<th><?php echo __('Longitude'); ?></th>
		<th><?php echo __('Created'); ?></th>
		<th><?php echo __('Modified'); ?></th>
		<th class="actions"><?php echo __('Actions');?></th>
	</tr>
	<?php
		$i = 0;
		foreach ($species['Occurrence'] as $occurrence): ?>
		<tr>
			<td><?php echo $occurrence['id'];?></td>
			<td><?php echo $occurrence['species_id'];?></td>
			<td><?php echo $occurrence['latitude'];?></td>
			<td><?php echo $occurrence['longitude'];?></td>
			<td><?php echo $occurrence['created'];?></td>
			<td><?php echo $occurrence['modified'];?></td>
			<td class="actions">
				<?php echo $this->Html->link(__('View'), array('controller' => 'occurrences', 'action' => 'view', $occurrence['id'])); ?>
				<?php echo $this->Html->link(__('Edit'), array('controller' => 'occurrences', 'action' => 'edit', $occurrence['id'])); ?>
				<?php echo $this->Form->postLink(__('Delete'), array('controller' => 'occurrences', 'action' => 'delete', $occurrence['id']), null, __('Are you sure you want to delete # %s?', $occurrence['id'])); ?>
			</td>
		</tr>
	<?php endforeach; ?>
	</table>
<?php endif; ?>

	<div class="actions">
		<ul>
			<li><?php echo $this->Html->link(__('New Occurrence'), array('controller' => 'occurrences', 'action' => 'add', '?' => array('species_id' => $species['Species']['id'])));?> </li>
		</ul>
	</div>
</div>
