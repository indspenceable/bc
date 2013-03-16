class SessionsController < ApplicationController
  skip_before_filter :redirect_to_select_username #, only: [:select_username, :register_username]

  def login
    return if session[:email_override]
    json_from_persona = `curl -d "assertion=#{params[:assertion]}&audience=#{request.protocol}#{request.host_with_port}" "https://verifier.login.persona.org/verify"`
    json_from_persona = JSON.parse(json_from_persona)
    if json_from_persona['status'] == "okay"
      email_addr = json_from_persona['email']
      flash[:notice] = "Successfully logged in as #{email_addr}" unless session[:email] == email_addr
      session[:email] = email_addr
      render :text => "login ok"
    else
      session[:email] = nil
      render :text => "login not ok"
    end
  end

  def logout
    session[:email] = nil
  end

  def dev_login
    session[:email] = params[:email]
    session[:email_override] = true
    User.find_or_create_by_email(session[:email], :name => "FAKE_USER_FOR#{session[:email]}")
    redirect_to games_path
  end

  def select_username
    redirect_to :landing unless session[:email]
    redirect_to :games if current_user
    @user = User.new
  end

  def register_username
    @user = User.new
    @user.name = params[:user][:name]
    @user.email = session[:email]

    if @user.save
      flash[:success] = "Successfully registered username."
      redirect_to :games
    else
      flash[:error] = "Sorry, that username has been taken."
      render :select_username
    end
  end
end
