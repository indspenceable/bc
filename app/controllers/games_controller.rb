class GamesController < LoggedInController
  before_filter :ensure_game, only: [:show, :ping, :update]

  def index
  end

  def show
    respond_to do |format|
      format.json { render json: game_state_hash }
      format.html do
        @player_id = current_game.player_id(current_user)
        @starting_configuration = game_state_hash.to_json
      end
    end
  end

  def ping
    render json: game_state_hash
  end

  def required_input_count
    #TODO make a column for this.
    render json: Game.where(active: true).where('p0_id = ? OR p1_id = ?', current_user.id, current_user.id).
      select{|game| game.play.required_input_for_player?(game.player_id current_user)}.length
  end

  def update
    #Return any answer for the given input
    current_game.input_and_save!(current_game.player_id(current_user), params['message'])
    render json: game_state_hash
  end

  private

  def game_state_hash
    {
      'gameState' => current_game.play.game_state(current_game.player_id(current_user)),
      'requiredInput' => current_game.play.all_required_input(current_game.player_id(current_user))
    }
  end

  helper_method :current_game
  def current_game
    @game ||= Game.find_by_id(params[:id])
  end

  def ensure_game
    redirect_to games_path unless current_game
  end
end
