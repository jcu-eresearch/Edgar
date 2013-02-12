require 'test_helper'

class SpeciesControllerTest < ActionController::TestCase
  setup do
    @emu = species(:emu)
    @queued_for_modelling = species(:queued_for_modelling)
    @only_has_one_deleted_vetting = species(:only_has_one_deleted_vetting)
    @occurrence_factory = Occurrence.rgeo_factory_for_column(:location)
    @vetting_factory = Vetting.rgeo_factory_for_column(:area)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get map" do
    get :map
    assert_response :success
  end

  test "should get occurrences as GeoJSON" do
    get(:occurrences, id: @emu, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

  end

  test "should update job status" do
    post(:job_status, id: @queued_for_modelling,
      job_status: Species::JOB_STATUS_LIST[:finished_successfully],
      job_status_message: "all good",
      dirty_occurrences: @queued_for_modelling.num_dirty_occurrences
    )
    assert_response :success

    @queued_for_modelling.reload
    assert_equal(nil, @queued_for_modelling.current_model_status)
    assert_equal(0, @queued_for_modelling.num_dirty_occurrences)
  end

  test "should get occurrences as WKT" do
    get(:occurrences, id: @emu, format: :text)
    assert_response :success

    features = @occurrence_factory.parse_wkt(@response.body)
    assert_kind_of(RGeo::Feature::GeometryCollection, features)
  end

  test "should get vettings as GeoJSON" do
    get(:vettings, id: @emu, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)
  end

  test "should get vettings as GeoJSON with custom limit (limit: 1)" do
    get(:vettings, id: @emu, format: :json, limit: 1)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(1, geom.size())
  end

  test "should get vettings as GeoJSON with custom limit (limit: 2)" do
    get(:vettings, id: @emu, format: :json, limit: 2)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(2, geom.size())
  end

  test "shouldn't get deleted vettings" do
    get(:vettings, id: @only_has_one_deleted_vetting, format: :json)
    assert_response :success

    geom = RGeo::GeoJSON.decode(@response.body, :json_parser => :json)
    assert_kind_of(RGeo::GeoJSON::FeatureCollection, geom)

    assert_equal(0, geom.size())
  end

  test "should get vettings as WKT" do
    get(:vettings, id: @emu, format: :text)
    assert_response :success

    features = @vetting_factory.parse_wkt(@response.body)
    assert_kind_of(RGeo::Feature::GeometryCollection, features)
  end

  test "shouldn't add vetting as not logged in" do
    area = "MULTIPOLYGON(((-12.12890625 58.768200159239576, 1.1865234375 58.49369382056807, 5.537109375 50.2612538275847, -12.9638671875 49.18170338770662, -12.12890625 58.768200159239576)))"
    assert_no_difference('Vetting.count') do
      raw_post(:add_vetting, {id: @emu, format: :json}, {area: area, classification: "historic", comment: "comment"}.to_json)
    end

    assert_response :unauthorized
  end

  test "should add vettings as WKT via post add_vetting" do
    sign_in users(:robert)

    area = "MULTIPOLYGON(((-12.12890625 58.768200159239576, 1.1865234375 58.49369382056807, 5.537109375 50.2612538275847, -12.9638671875 49.18170338770662, -12.12890625 58.768200159239576)))"

    assert_difference('Vetting.count') do
      raw_post(:add_vetting, {id: @emu, format: :json}, {area: area, classification: "historic", comment: "comment"}.to_json)
    end

    assert_response :success
  end

  test "should not add vettings as user not permitted (can_vet false)" do
    sign_in users(:no_can_vet)

    area = "MULTIPOLYGON(((-12.12890625 58.768200159239576, 1.1865234375 58.49369382056807, 5.537109375 50.2612538275847, -12.9638671875 49.18170338770662, -12.12890625 58.768200159239576)))"

    assert_no_difference('Vetting.count') do
      raw_post(:add_vetting, {id: @emu, format: :json}, {area: area, classification: "historic", comment: "comment"}.to_json)
    end

    assert_response :unauthorized
  end

end
