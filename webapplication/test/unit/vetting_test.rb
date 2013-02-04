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

require 'test_helper'

class VettingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
