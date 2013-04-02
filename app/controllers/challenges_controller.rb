class ChallengesController < ApplicationController
  def new
    @challenge = Challenge.new
  end

  def create

    challenge_params = params[:challenge]
    issuer = current_user
    reciever = User.find_by_name(challenge_params[:opponent])
    challenge_params.delete(:opponent)

    @challenge = Challenge.new(params[:challenge])
    @challenge.issuing_user = issuer
    @challenge.receiving_user = reciever
    @challenge.save!
    redirect_to challenge_path(@challenge)
  end

  def show
    @challenge = Challenge.find(params[:id])
  end

  def update
    @challenge = Challenge.find(params[:id])
    unless @challenge.receiving_user == current_user
      # flash[:error] = "You can't respond to that challenge."
      # return redirect_to user_path(current_user)
    end
    if params[:commit] == "Accept Challenge"
      return redirect_to @challenge.build_game_and_mark_inactive!

    elsif params[:commit] == "Reject Challenge"
      flash[:notice] = "Challenge rejected."
      @challenge.inactive = true
      @challenge.save!
      return redirect_to user_path(current_user)
    else
      flash[:error] = "Unrecognized response."
      return redirect_to challenge_path(@challenge)
    end
  end
end
