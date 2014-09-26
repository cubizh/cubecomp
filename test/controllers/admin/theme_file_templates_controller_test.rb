require 'test_helper'

class Admin::ThemeFileTemplatesControllerTest < ActionController::TestCase
  setup do
    @template = theme_file_templates(:default_index)
    @theme = @template.theme
    login_as(users(:admin))
  end

  test '#new' do
    get :new, theme_id: @theme.id
    assert_response :success
  end

  test '#create' do
    params = {
      filename: 'foobar.html',
      content: 'foobar'
    }

    assert_difference('ThemeFileTemplate.count') do
      post :create, theme_id: @theme.id, theme_file_template: params
    end

    assert_redirected_to edit_admin_theme_theme_file_template_path(assigns(:theme), assigns(:template))
    assert_attributes(params, ThemeFileTemplate.last)
  end

  test '#edit' do
    get :edit, theme_id: @theme.id, id: @template.id
    assert_response :success
  end

  test '#update' do
    params = {
      filename: 'foobar.html',
      content: 'foobar'
    }

    patch :update, theme_id: @theme.id, id: @template.id, theme_file_template: params

    assert_redirected_to edit_admin_theme_theme_file_template_path(assigns(:theme), assigns(:template))
    assert_attributes(params, @template.reload)
  end

  test '#destroy' do
    assert_difference('ThemeFileTemplate.count', -1) do
      delete :destroy, theme_id: @theme.id, id: @template.id
    end

    assert_redirected_to admin_theme_path(@template.theme)
  end
end
