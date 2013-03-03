class GamesController < ApplicationController
  before_filter :locate_game
  def show
    respond_to do |format|
      format.json { render json: game_state_hash }
      format.html do
        @player_id = params[:player_id].to_i
        @starting_configuration = game_state_hash.to_json
      end
    end
  end

  def ping
    render json: game_state_hash
  end

  def update
    #Return any answer for the given input
    @game.input_and_save!(params['player_id'].to_i, params['message'])
    render json: game_state_hash
  end

  private

  def game_state_hash
    {
      'gameState' => @game.play.game_state(params['player_id'].to_i),
      'requiredInput' => @game.play.required_input[params['player_id'].to_i]
    }
  end

  def locate_game
    @game =   Game.find_by_id(params[:id])
    unless @game
      @game = Game.new(inputs: [])
      @game.id = params[:id]
      @game.save!
    end
    @game
  end
end
