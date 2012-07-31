<table>
    <tr>
        <th>Scientific Name</th>
        <th>Common Name</th>
        <th></th>
    </tr>
    <?php foreach ($contentious_species as $species): ?>
        <tr>
            <td><?php print h($species['scientific_name']); ?>&nbsp;</td>
            <td><?php print h($species['common_name']); ?>&nbsp;</td>
            <td class="actions">
                <?php print $this->Html->link(__('View Map'),  array('action' => 'map', $species['id'])); ?>
            </td>
        </tr>
    <?php endforeach; ?>
</table>
