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

class User < ActiveRecord::Base
  # Include devise modules for cas authentication
  devise :cas_authenticatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username
  attr_readonly :authority, :can_vet, :email, :fname, :is_admin, :lname

  has_many :vettings

  before_destroy :check_for_vettings

  def cas_extra_attributes=(extra_attributes)
    extra_attributes.each do |name, value|
      case name.to_sym
      when :firstname
        self.fname = value
      when :lastname
        self.lname = value
      when :email
        self.email = value
      end
    end
  end

  private

  def prevent_destroy
    if vettings.count > 0
      errors.add_to_base("Can't destroy a user with vettings")
      false
    end
  end
end
