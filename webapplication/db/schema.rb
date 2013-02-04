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

ActiveRecord::Schema.define(:version => 20130204015233) do

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
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
  end

end
