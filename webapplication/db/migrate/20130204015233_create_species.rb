class CreateSpecies < ActiveRecord::Migration
  def change
    create_table :species do |t|
      t.string :scientific_name,                              null: false
      t.string :common_name
      t.integer :num_dirty_occurrences,       default: 0,     null: false
      t.integer :num_contentious_occurrences, default: 0,     null: false
      t.timestamp :needs_vetting_since
      t.boolean :has_occurrences,             default: false, null: false

      # Modelling status (current)
      t.timestamp :first_requested_remodel
      t.string :current_model_status
      t.timestamp :current_model_queued_time
      t.integer :current_model_importance

      # Modelling most recently completed
      t.timestamp :last_completed_model_queued_time
      t.timestamp :last_completed_model_finish_time
      t.integer :last_completed_model_importance
      t.string :last_completed_model_status
      t.string :last_completed_model_status_reason

      # Modelling most recently successfully completed
      t.timestamp :last_successfully_completed_model_queued_time
      t.timestamp :last_successfully_completed_model_finish_time
      t.integer :last_successfully_completed_model_importance
      t.timestamp :last_applied_vettings

    end
  end
end
