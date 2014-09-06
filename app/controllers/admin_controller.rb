class AdminController < ApplicationController
  layout 'admin'

  def current_user
    @current_user ||= begin
      User.first
    end
  end
  helper_method :current_user

  def current_competition
    @current_competition ||= begin
      competition = if competition_id = params[:competition_id] || session[:competition_id]
        current_user.competitions.find(competition_id)
      end

      competition || current_user.competitions.first
    end
  end
  helper_method :current_competition

  def super_admin_menu
    items = [
      {
        label: 'Competitions',
        controller: Admin::CompetitionsController,
        url: admin_competitions_path,
        css: 'fa-wrench'
      },
      {
        label: 'Users',
        controller: Admin::UsersController,
        url: admin_users_path,
        css: 'fa-user'
      }
    ]

    MenuItem.parse(self, items)
  end
  helper_method :super_admin_menu

  def navigation_menu
    items = [
      {
        label: 'Dashboard',
        controller: Admin::DashboardController,
        url: admin_competition_dashboard_index_path(current_competition),
        css: 'fa-dashboard'
      },
      {
        label: 'Competitors',
        controller: Admin::CompetitorsController,
        url: admin_competition_competitors_path(current_competition),
        css: 'fa-list-alt'
      },
      {
        label: 'Events',
        controller: Admin::EventsController,
        url: admin_competition_events_path(current_competition),
        css: 'fa-table'
      },
      {
        label: 'News',
        controller: Admin::NewsController,
        url: admin_competition_news_index_path(current_competition),
        css: 'fa-star'
      },
      {
        label: 'Theme',
        controller: Admin::ThemeFilesController,
        url: admin_competition_theme_files_path(current_competition),
        css: 'fa-files-o'
      },
      {
        label: 'Settings',
        controller: Admin::CompetitionsController,
        actions: ['edit'],
        url: edit_admin_competition_path(current_competition),
        css: 'fa-wrench'
      }
    ]

    MenuItem.parse(self, items)
  end
  helper_method :navigation_menu
end
