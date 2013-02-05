# == Schema Information
#
# Table name: vettings
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  species_id     :integer          not null
#  comment        :text             not null
#  classification :classification   not null
#  created        :datetime         not null
#  modified       :datetime         not null
#  deleted        :datetime
#  ignored        :datetime
#  last_ala_sync  :datetime
#

class Vetting < ActiveRecord::Base
  attr_accessible :classification, :comment
  attr_readonly :classification, :comment, :last_ala_sync, :species_id, :user_id

  belongs_to :species
  belongs_to :user

  before_destroy :prevent_destroy

  private

  def prevent_destroy
    errors.add(:base, "Can't destroy a vetting")
    false
  end
end
