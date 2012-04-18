<div class="species view">
<h2><?php  echo __('Species');?></h2>
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
		<dt><?php echo __('Number of Dirty Occurrences'); ?></dt>
		<dd>
			<?php echo h($species['Species']['num_dirty_occurrences']); ?>
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
		<li><?php echo $this->Html->link(__('List Species'), array('action' => 'index')); ?> </li>
		<li><?php echo $this->Html->link(__('List Occurrences'), array('controller' => 'occurrences', 'action' => 'index')); ?> </li>
	</ul>
</div>

</div>
