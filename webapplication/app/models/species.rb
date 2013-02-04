# == Schema Information
#
# Table name: species
#
#  id                                            :integer          not null, primary key
#  scientific_name                               :string(255)      not null
#  common_name                                   :string(255)
#  num_dirty_occurrences                         :integer          default(0), not null
#  num_contentious_occurrences                   :integer          default(0), not null
#  needs_vetting_since                           :datetime
#  has_occurrences                               :boolean          default(FALSE), not null
#  first_requested_remodel                       :datetime
#  current_model_status                          :string(255)
#  current_model_queued_time                     :datetime
#  current_model_importance                      :integer
#  last_completed_model_queued_time              :datetime
#  last_completed_model_finish_time              :datetime
#  last_completed_model_importance               :integer
#  last_completed_model_status                   :string(255)
#  last_completed_model_status_reason            :string(255)
#  last_successfully_completed_model_queued_time :datetime
#  last_successfully_completed_model_finish_time :datetime
#  last_successfully_completed_model_importance  :integer
#  last_applied_vettings                         :datetime
#  created_at                                    :datetime         not null
#  updated_at                                    :datetime         not null
#

class Species < ActiveRecord::Base
  attr_accessible :common_name, :current_model_importance, :current_model_queued_time, :current_model_status, :first_requested_remodel, :has_occurrences, :last_applied_vettings, :last_completed_model_finish_time, :last_completed_model_importance, :last_completed_model_queued_time, :last_completed_model_status, :last_completed_model_status_reason, :last_successfully_completed_model_finish_time, :last_successfully_completed_model_importance, :last_successfully_completed_model_queued_time, :needs_vetting_since, :num_contentious_occurrences, :num_dirty_occurrences, :scientific_name
end
