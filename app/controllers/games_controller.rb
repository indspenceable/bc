class GamesController < LoggedInController
  before_filter :ensure_game, only: [:show, :ping, :update]

  def index
  end

  def challenge
    opponent = User.find(params[:opponent_id])
    raise "Can't play against yourself!" if opponent.id == current_user.id
    # is there a game vs this opponent?
    game = Game.active_between(current_user, opponent)
    unless game
      # We need to create a game
      game = Game.create(
        :p0_id => current_user.id,
        :p1_id => opponent.id,
        :active => true,
        :inputs => [])
    end
    redirect_to game_path(game)
  end

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
    current_game.input_and_save!(params['player_id'].to_i, params['message'])
    render json: game_state_hash
  end

  private

  def game_state_hash
    {
      'gameState' => current_game.play.game_state(params['player_id'].to_i),
      'requiredInput' => current_game.play.required_input[params['player_id'].to_i]
    }
  end

  def current_game
    @game ||= Game.find_by_id(params[:id])
  end

  def ensure_game
    puts "current action is #{params[:action]}"
    redirect_to games_path unless current_game
  end
end
