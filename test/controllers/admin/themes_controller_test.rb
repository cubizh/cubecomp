require 'test_helper'

class Admin::ThemesControllerTest < ActionController::TestCase
  setup do
    login_as(users(:admin))
    @theme = themes(:default)
  end

  test "#index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:themes)
  end

  test "#show" do
    get :show, id: @theme
    assert_response :success
  end

  test "#show renders 404 with invalid competition id" do
    get :show, id: 17
    assert_response :not_found
  end
end
