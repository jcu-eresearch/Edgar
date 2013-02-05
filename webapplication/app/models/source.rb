# == Schema Information
#
# Table name: sources
#
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  url              :string(255)      default(""), not null
#  last_import_time :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Source < ActiveRecord::Base
  attr_readonly :last_import_time, :name, :url

  has_many :occurrences

  before_destroy :check_for_occurrences

  private

  def check_for_occurrences
    if occurrences.count > 0
      errors.add(:base, "Can't destroy a source with occurrences")
      false
    end
  end
end
