class ChallengesController < ApplicationController
  def new
    @challenge = Challenge.new
  end

  def create
    challenge_params = params[:challenge]
    challenge_params[:from_id] = current_user.id
    challenge_params[:to_id] = User.find_by_name(challenge_params[:opponent]).id
    challenge_params.delete(:opponent)
    @challenge = Challenge.new(params[:challenge])
    @challenge.save
    redirect_to challenge_path(@challenge)
  end

  def show
    @challenge = Challenge.find(params[:id])
  end

  def update
    raise "DERP"
  end
end
