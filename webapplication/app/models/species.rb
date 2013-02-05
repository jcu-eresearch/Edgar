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
  # These attributes are readonly
  attr_readonly :common_name, :scientific_name, :last_applied_vettings, :needs_vetting_since
  # All other attributes will default to attr_protected (non mass assignable)

  has_many :occurrences
  has_many :vettings

  before_destroy :check_for_occurrences_or_vettings

  private

  def check_for_occurrences_or_vettings
    if occurrences.count > 0 or vettings.count > 0
      errors.add(:base, "Can't destroy a species with occurrences or vettings")
      false
    end
  end
end
