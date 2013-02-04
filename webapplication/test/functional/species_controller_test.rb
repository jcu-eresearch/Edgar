require 'test_helper'

class SpeciesControllerTest < ActionController::TestCase
  setup do
    @emu = species(:emu)
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get show" do
    get :show, id: @emu
    assert_response :success
  end

  test "should get map" do
    get :map
    assert_response :success
  end

end
