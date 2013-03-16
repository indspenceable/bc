class ApplicationController < ActionController::Base
  before_filter :redirect_to_select_username

  protect_from_forgery

  private

  helper_method :current_user
  def current_user
    User.find_by_email(session[:email])
  end

  def redirect_to_select_username
    redirect_to :select_username if !current_user && session[:email]
  end
end
