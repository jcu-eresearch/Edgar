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

require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
