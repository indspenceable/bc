class Game
  # returns a hash from player_id to the input they need
  def required_input
    {
      0 => "select_character",
      1 => "select_character",
    }
  end
  # are we waiting on input from this player id?
  def required_input_for_player?(player_id)
    required_input.keys.include?(player_id)
  end
  # returns a hash containing useful information about the gamestate
  # :events - a list of things that have happened
  # player_id - that players game_state
  # if you hand it a player_id, it will provide you more information
  def game_state(player_id)
    {
      :events => [],
      0 => player_info_for(0, player_id),
      1 => player_info_for(0, player_id),
    }
  end

  private

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    nil
  end
end
