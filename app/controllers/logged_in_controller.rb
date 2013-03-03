class LoggedInController < ApplicationController
  before_filter :ensure_logged_in

  private

  def ensure_logged_in
    redirect_to :landing unless current_user
  end
end
