# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130303061557) do

  create_table "cached_occurrence_clusters", :force => true do |t|
    t.integer "species_cache_record_id",                                                  :null => false
    t.integer "cluster_size",                                                             :null => false
    t.integer "contentious_count",                                                        :null => false
    t.integer "unknown_count"
    t.integer "contentious_unknown_count"
    t.integer "invalid_count"
    t.integer "contentious_invalid_count"
    t.integer "historic_count"
    t.integer "contentious_historic_count"
    t.integer "vagrant_count"
    t.integer "contentious_vagrant_count"
    t.integer "irruptive_count"
    t.integer "contentious_irruptive_count"
    t.integer "core_count"
    t.integer "contentious_core_count"
    t.integer "introduced_count"
    t.integer "contentious_introduced_count"
    t.spatial "cluster_centroid",             :limit => {:srid=>4326, :type=>"point"}
    t.spatial "cluster_envelope",             :limit => {:srid=>4326, :type=>"geometry"}
    t.spatial "buffered_cluster_envelope",    :limit => {:srid=>4326, :type=>"geometry"}
  end

  add_index "cached_occurrence_clusters", ["cluster_centroid"], :name => "index_cached_occurrence_clusters_on_cluster_centroid"
  add_index "cached_occurrence_clusters", ["species_cache_record_id"], :name => "index_cached_occurrence_clusters_on_species_cache_record_id"

# Could not dump table "occurrences" because of following StandardError
#   Unknown type 'classification' for column 'classification'

  create_table "sensitive_occurrences", :force => true do |t|
    t.integer "occurrence_id",                                               :null => false
    t.spatial "sensitive_location", :limit => {:srid=>4326, :type=>"point"}
  end

  add_index "sensitive_occurrences", ["occurrence_id"], :name => "index_sensitive_occurrences_on_occurrence_id"
  add_index "sensitive_occurrences", ["sensitive_location"], :name => "index_sensitive_occurrences_on_sensitive_location", :spatial => true

  create_table "sources", :force => true do |t|
    t.string   "name",                             :null => false
    t.string   "url",              :default => "", :null => false
    t.datetime "last_import_time"
  end

  create_table "species", :force => true do |t|
    t.string   "scientific_name",                                                  :null => false
    t.string   "common_name"
    t.integer  "num_dirty_occurrences",                         :default => 0,     :null => false
    t.integer  "num_contentious_occurrences",                   :default => 0,     :null => false
    t.datetime "needs_vetting_since"
    t.boolean  "has_occurrences",                               :default => false, :null => false
    t.datetime "first_requested_remodel"
    t.string   "current_model_status"
    t.datetime "current_model_queued_time"
    t.integer  "current_model_importance"
    t.datetime "last_completed_model_queued_time"
    t.datetime "last_completed_model_finish_time"
    t.integer  "last_completed_model_importance"
    t.string   "last_completed_model_status"
    t.string   "last_completed_model_status_reason"
    t.datetime "last_successfully_completed_model_queued_time"
    t.datetime "last_successfully_completed_model_finish_time"
    t.integer  "last_successfully_completed_model_importance"
    t.datetime "last_applied_vettings"
  end

  create_table "species_cache_records", :force => true do |t|
    t.integer  "species_id",         :null => false
    t.float    "grid_size"
    t.datetime "cache_generated_at", :null => false
    t.datetime "out_of_date_since"
  end

  add_index "species_cache_records", ["grid_size"], :name => "index_species_cache_records_on_grid_size"
  add_index "species_cache_records", ["out_of_date_since"], :name => "index_species_cache_records_on_out_of_date_since"
  add_index "species_cache_records", ["species_id"], :name => "index_species_cache_records_on_species_id"

  create_table "users", :force => true do |t|
    t.string  "email"
    t.string  "fname",                        :null => false
    t.string  "lname",                        :null => false
    t.boolean "can_vet",   :default => true,  :null => false
    t.boolean "is_admin",  :default => false, :null => false
    t.integer "authority", :default => 1000,  :null => false
    t.string  "username",                     :null => false
  end

  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

# Could not dump table "vettings" because of following StandardError
#   Unknown type 'classification' for column 'classification'

end
