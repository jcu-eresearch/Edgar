# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string(255)
#  fname      :string(255)      not null
#  lname      :string(255)      not null
#  can_vet    :boolean          default(TRUE), not null
#  is_admin   :boolean          default(FALSE), not null
#  authority  :integer          default(1000), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
