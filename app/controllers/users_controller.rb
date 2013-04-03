class UsersController < LoggedInController
  def show
    @user = User.from_param(params[:id])
    # return redirect_to :landing unless @user == current_user
  end

  def update
    @user = User.from_param(params[:id])
    return redirect_to :landing unless @user == current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'Settings successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "show" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
end
