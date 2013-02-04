class CreateSensitiveOccurrences < ActiveRecord::Migration
  def change
    create_table :sensitive_occurrences do |t|
      t.integer :occurrence_id, null: false
      t.point :sensitive_location, srid: 4326

      t.timestamps
    end

    change_table :sensitive_occurrences do |t|
      t.index :sensitive_location, spatial: true
      t.index :occurrence_id
    end
  end
end
