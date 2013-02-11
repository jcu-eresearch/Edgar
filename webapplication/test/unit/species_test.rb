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

require 'test_helper'

class SpeciesTest < ActiveSupport::TestCase

  setup do
    @emu = species(:emu)
    @rock_parrot = species(:rock_parrot)
  end

  test "Common name is read only" do
    original_common_name = @emu.common_name
    @emu.common_name = "Big Bird"
    @emu.save
    @emu.reload

    assert_equal(original_common_name, @emu.common_name)
    assert_not_equal("Big Bird", @emu.common_name)
  end

  test "Scientific Name is read only" do
    original_scientific_name = @emu.scientific_name
    @emu.scientific_name = "Jimmy"
    @emu.save
    @emu.reload

    assert_equal(original_scientific_name, @emu.scientific_name)
    assert_not_equal("Jimmy", @emu.scientific_name)
  end

  test "Can't mass assign common name" do
    assert_raise(ActiveModel::MassAssignmentSecurity::Error) do
      @emu.update_attributes(:common_name => "Big Bird")
    end
  end

  test "Can't mass assign last_applied_vettings" do
    assert_raise(ActiveModel::MassAssignmentSecurity::Error) do
      @emu.update_attributes(:last_applied_vettings => Time.now)
    end
  end

  test "GeoJSON output for clustered points includes cluster_size property" do
    json = @emu.get_occurrences_geo_json()

    feature_hash = json["features"].first
    cluster_size = feature_hash["properties"]["cluster_size"]
    assert_kind_of(
      Integer,
      cluster_size,
      "cluster_size property should have " +
      "been a kind of Integer. Instead it is: #{cluster_size.inspect}"
    )
    assert(
      (cluster_size >= 0),
      "cluster_size property should have been greater than 0"
    )
  end

end
