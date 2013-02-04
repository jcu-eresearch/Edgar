class CreateVettings < ActiveRecord::Migration
  def up
    create_table :vettings do |t|
      t.integer :user_id,                         null: false
      t.integer :species_id,                      null: false
      t.text :comment,                            null: false
      t.column :classification, 'classification', null: false
      t.timestamp :created,                       null: false
      t.timestamp :modified,                      null: false
      t.timestamp :deleted
      t.timestamp :ignored
      t.timestamp :last_ala_sync

      t.geometry :area, type: "multipolygon", srid: 4326
    end

    # Add foreign key and spatial indices
    change_table :vettings do |t|
      t.index :user_id
      t.index :species_id
      t.index :area, spatial: true
    end

    execute <<-SQL
      ALTER TABLE vettings ALTER COLUMN created SET DEFAULT now();
      ALTER TABLE vettings ALTER COLUMN modified SET DEFAULT now();
    SQL
  end

  def down
    drop_table :vettings
  end

end
