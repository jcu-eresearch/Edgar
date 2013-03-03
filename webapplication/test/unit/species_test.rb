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
    @queued_for_modelling_species = species(:queued_for_modelling)
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

  test "GeoJSON output for clustered (with grid_size and bbox defined) points includes cluster_size property" do
    json = @emu.get_occurrences_geo_json(cluster: true, grid_size: 10, bbox: "-180,-90,180,90")

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

  test "GeoJSON output for clustered occurrences contains the correct classification counts" do
    options = {}
    options[:limit] = 1
    options[:cluster] = true
    options[:grid_size] = 360
    results = @emu.get_occurrences_geo_json(options)
    feature = results["features"].first()
    properties = feature["properties"]
    classification_totals = properties["classificationTotals"]
    assert_equal(1, results["features"].length, "With a grid size of 360 degrees (covering the earth), there should only be 1 cluster returned")

    Classification::STANDARD_CLASSIFICATIONS.each do |classification|
      expected_count = @emu.occurrences.count(conditions: ["classification = ?", classification])

      actual_count = 0
      classification_hash = classification_totals.select { |el|
        el[:label] == classification
      }.first

      if classification_hash
        actual_count = classification_hash[:total]
      else
        actual_count = 0
      end

      assert_equal(expected_count, actual_count, "There should be #{expected_count} records with a classification of #{classification}")
    end

  end

  test "Updating the status of a job to finished should update species correctly (with same dirty occurrence counts)" do
    dirty_occurrences = @queued_for_modelling_species.num_dirty_occurrences
    assert(dirty_occurrences > 0, "species needs some dirty occurrences in the first place, else test is pointless")
    @queued_for_modelling_species.update_job_status!(Species::JOB_STATUS_LIST[:finished_successfully], "success is great", dirty_occurrences)
    @queued_for_modelling_species.reload

    assert_equal(0, @queued_for_modelling_species.num_dirty_occurrences, "should not be anymore dirty occurrences")
    assert_nil(@queued_for_modelling_species.current_model_status)
    assert_nil(@queued_for_modelling_species.current_model_importance)
    assert_nil(@queued_for_modelling_species.current_model_queued_time)
    assert_nil(@queued_for_modelling_species.first_requested_remodel)

    assert_equal("success is great", @queued_for_modelling_species.last_completed_model_status_reason)

  end

  test "Updating the status of a job to finished should update species correctly (with different dirty occurrence counts)" do
    dirty_occurrences = @queued_for_modelling_species.num_dirty_occurrences
    assert(dirty_occurrences > 0, "species needs some dirty occurrences in the first place, else test is pointless")
    @queued_for_modelling_species.update_job_status!(Species::JOB_STATUS_LIST[:finished_successfully], "success is golden", 1)
    @queued_for_modelling_species.reload

    assert_equal(dirty_occurrences, @queued_for_modelling_species.num_dirty_occurrences, "dirty occurrences should remain unchanged")

    assert_nil(@queued_for_modelling_species.current_model_status)
    assert_nil(@queued_for_modelling_species.current_model_importance)
    assert_nil(@queued_for_modelling_species.current_model_queued_time)
    assert_nil(@queued_for_modelling_species.first_requested_remodel)

    assert_equal("success is golden", @queued_for_modelling_species.last_completed_model_status_reason)

  end
end
