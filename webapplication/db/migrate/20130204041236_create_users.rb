class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :fname,                      null: false
      t.string :lname,                      null: false
      t.boolean :can_vet,   default: true,  null: false
      t.boolean :is_admin,  default: false, null: false
      t.integer :authority, default: 1000,  null: false

    end
  end
end
