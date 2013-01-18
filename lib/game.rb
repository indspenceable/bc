class Game
  # Input manager manages input.
  class InputManager
    def initialize
      @required_input = {}
    end
    def require_single_input!(player_id, input_string, validator)
      raise "Didn't answer previous question" if input_required?
      @required_input = {
        player_id => [input_string, validator]
      }
    end
    def require_multi_input!(input_string, *validators)
      raise "Didn't answer previous question" if input_required?
      @required_input = {}
      validators.each_with_index do |validator, idx|
        @required_input[idx] = [input_string, validator]
      end
    end
    def required_input
      Hash[@required_input.map do |k,v|
        [k, v.first]
      end]
    end
    def answer!(player_id, string)
      raise "We weren't asking that player for anything." unless @required_input.key?(player_id)
      _, validator = @required_input[player_id]
      raise "Invalid answer" unless validator.call(string)
      @answers[player_id] = answer
    end
    def input_required?
      @required_input.keys.any?{|k| !@answers.key?(k) }
    end
    def answer
      @answers
    end
  end

  def initialize
    @input_manager = InputManager.new
    @input_manager.require_multi_input!("select_character",
      ->(text) { text.downcase == "hikaru" },
      ->(text) { text.downcase == "hikaru" }
    )
  end

  # returns a hash from player_id to the input they need
  def required_input
    @input_manager.required_input
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
      1 => player_info_for(1, player_id),
      :current_phase => "select_character"
    }
  end

  private

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    nil
  end
end
