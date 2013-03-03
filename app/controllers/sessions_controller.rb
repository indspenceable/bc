class SessionsController < ApplicationController
  def login
    json_from_persona = `curl -d "assertion=#{params[:assertion]}&audience=localhost" "https://verifier.login.persona.org/verify"`
    json_from_persona = JSON.parse(json_from_persona)
    if json_from_persona['status'] == "okay"
      flash[:notice] = "Logged in!"
      session[:email] = json_from_persona['email']
      User.find_or_create_by_email(session[:email])
      render :text => "login ok"
    else
      render :text => "login not ok"
    end
  end

  def logout
    session[:email] = nil
  end
end
