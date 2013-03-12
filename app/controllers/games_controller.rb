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
      game = Game.create!(
        :p0_id => current_user.id,
        :p1_id => opponent.id,
        :active => true,
        :inputs => [])

      # Deliver an email
      UserMailer.challenge(opponent, current_user, game).deliver if opponent.email_notifications_enabled?
    end
    redirect_to game_path(game)
  end

  def show
    respond_to do |format|
      format.json { render json: game_state_hash }
      format.html do
        @player_id = current_game.player_id(current_user)
        @starting_configuration = game_state_hash.to_json
        @existing_game_steps = event_index_to_game_state_hashes(current_game.player_id(current_user), 0).values.to_json
      end
    end
  end

  def ping
    render json: event_index_to_game_state_hashes(current_game.player_id(current_user), Integer(params[:index]))
  end

  def required_input_count
    #TODO make a column for this.
    render json: Game.where(active: true).where('p0_id = ? OR p1_id = ?', current_user.id, current_user.id).
      select{|game| game.play.required_input[game.player_id current_user]}.length
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
      'requiredInput' => current_game.play.required_input[current_game.player_id(current_user)]
    }
  end

  def event_index_to_game_state_hashes(pn, index)
    last_index = current_game.play.event_index
    gs_list = {}
    (index..last_index).each do |i|
      hsh = {
      'gameState' => current_game.play(i).game_state(current_game.player_id(current_user)),
      }
      # if i == last_index
      #   hsh['requiredInput'] = current_game.play.required_input[current_game.player_id(current_user)]
      # end
      gs_list[i] = hsh
    end
    if current_game.play(last_index).required_input[pn]
      gs_list[last_index] = {
        'gameState' => current_game.play.game_state(current_game.player_id(current_user)),
        'requiredInput' => current_game.play.required_input[current_game.player_id(current_user)]
      }
    end
    puts "Gs list looks like #{gs_list}"
    gs_list
  end


  helper_method :current_game
  def current_game
    @game ||= Game.find_by_id(params[:id])
  end

  def ensure_game
    redirect_to games_path unless current_game
  end
end
