class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :name,               null: false
      t.string :url,  default: '',  null: false
      t.timestamp :last_import_time

      t.timestamps
    end
  end
end
