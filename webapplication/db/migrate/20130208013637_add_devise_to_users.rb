class AddDeviseToUsers < ActiveRecord::Migration

  def change
    change_table(:users) do |t|
      ## CAS authenticatable
      t.string :username,              :null => false
    end

    add_index :users, :username, :unique => true
  end

end
