module ApplicationHelper
  def flash_to_alert
    {
      :notice => "alert-info",
      :error => 'alert-error',
      :success => 'alert-success'
    }
  end
end
