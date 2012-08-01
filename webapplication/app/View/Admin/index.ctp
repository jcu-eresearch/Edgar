<?php if(count($contentious_species) > 0): ?>
    <table>
        <tr>
            <th>No. Contentious</th>
            <th>Scientific Name</th>
            <th>Common Name</th>
            <th></th>
        </tr>
        <?php foreach ($contentious_species as $species): ?>
            <tr>
                <td><?php print h($species['num_contentious_occurrences']) ?></td>
                <td><?php print h($species['scientific_name']); ?>&nbsp;</td>
                <td><?php print h($species['common_name']); ?>&nbsp;</td>
                <td class="actions">
                    <?php print $this->Html->link(__('View Map'),  array('controller' => 'species', 'action' => 'map', $species['id'])); ?>
                </td>
            </tr>
        <?php endforeach ?>
    </table>
<?php else: ?>
    <p>No species currently have contentious occurrences.</p>
<?php endif ?>
