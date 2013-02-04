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
  attr_accessible :classification, :comment, :created, :deleted, :ignored, :last_ala_sync, :modified, :species_id, :user_id
end
