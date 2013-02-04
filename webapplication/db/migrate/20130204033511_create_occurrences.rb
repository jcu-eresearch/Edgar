class CreateOccurrences < ActiveRecord::Migration
  def change
    create_table :occurrences do |t|
      t.integer :uncertainty
      t.date :date
      t.column :classification, 'classification', null: false
      t.column :basis, 'occurrence_basis'
      t.boolean :contentious, default: false, null: false
      t.column :source_classification, 'classification'
      t.binary :source_record_id

      t.integer :species_id, null: false
      t.integer :source_id, null: false

      t.point :location, srid: 4326

      t.timestamps
    end

    change_table :occurrences do |t|
      t.index :location, spatial: true
      t.index :species_id
    end
  end
end
