class Character; end
class Hikaru < Character
  def self.name
    "hikaru"
  end
  def initialize
  end
  def valid_discard_callback
    ->(text) { text =~ /[a-z]*_[a-z]*;[a-z]*_[a-z]*/}
  end
  def valid_attack_pair_callback
    ->(text) { text =~ /[a-z]*_[a-z]*/ }
  end
end

class Game
  # Input manager manages input.
  class InputManager
    def initialize(input_buffer)
      @required_input = {}
      @input_buffer = Hash.new{|h, k| h[k] = []}
      input_buffer.each do |player_id, str|
        @input_buffer[player_id] << str
      end
    end
    def require_single_input!(player_id, input_string, validator)
      raise "Didn't answer previous question" if input_required?
      @answers = {}
      @required_input = {
        player_id => [input_string, validator]
      }
      answer_inputs!
    end
    def require_multi_input!(input_string, *validators)
      raise "Didn't answer previous question" if input_required?
      @answers = {}
      @required_input = {}
      validators.each_with_index do |validator, idx|
        @required_input[idx] = [input_string, validator]
      end
      answer_inputs!
    end
    def required_input
      Hash[@required_input.map do |k,v|
        [k, v.first]
      end]
    end
    def answer(player_id)
      @answers[player_id]
    end

    private

    def answer_inputs!
      @required_input.keys.each do |player_id|
        if @input_buffer[player_id].any?
          answer!(player_id, @input_buffer[player_id].shift)
        end
      end
      throw :input_required if input_required?
      @answers
    end
    def answer!(player_id, string)
      raise "We weren't asking that player for anything." unless @required_input.key?(player_id)
      _, validator = @required_input[player_id]
      raise "Invalid answer to #{@required_input[player_id].first}" unless validator.call(string)
      @required_input.delete(player_id)
      @answers[player_id] = string.downcase
    end
    def input_required?
      @required_input.keys.any?{|k| !@answers.key?(k) }
    end
  end

  def initialize
    @valid_inputs_thus_far = []
    setup_game!(@valid_inputs_thus_far)
  end

  def setup_game!(inputs)
    @input_manager = InputManager.new(inputs)
    @player_locations = {
      0 => 1,
      1 => 5,
    }
    catch :input_required do
      select_characters!
      select_discards!
      15.times do |round_number|
        @round_number = round_number + 1 # 1 based
        @input_manager.require_multi_input!("select_attack_pairs",
          # these should shell out to character's individual callbacks.
          ->(text) { text =~ /[a-z]*_[a-z]*/ },
          ->(text) { text =~ /[a-z]*_[a-z]*/ }
        )
      end
    end
  end

  def input!(player_id, str)
    setup_game!(@valid_inputs_thus_far + [[player_id, str]])
    @valid_inputs_thus_far << [player_id, str]
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
  def game_state(player_id=nil)
    {
      :events => [],
      :players => [
        player_info_for(0, player_id),
        player_info_for(1, player_id)
      ],
      :current_phase => "select_character"
    }
  end

  private

  # phases of the game
  def select_characters!
    #character selection
    @input_manager.require_multi_input!("select_character",
      ->(text) { character_names.include?(text) },
      ->(text) { character_names.include?(text) }
    )
    # for now, just consume input.
    @player0 = character_list[character_names.index @input_manager.answer(0)].new
    @player1 = character_list[character_names.index @input_manager.answer(1)].new
  end
  def select_discards!
    # select_discards
    @input_manager.require_multi_input!("select_discards",
      # these should shell out to characters individual methods, for roberts
      # sake.
      @player0.valid_discard_callback,
      @player1.valid_discard_callback
    )
    @player0.set_initial_discards!(@input_manager.answer(0))
    @player1.set_initial_discards!(@input_manager.answer(1))
  end

  def select_attack_pairs!
    @input_manager.require_multi_input!("select_attack_pairs",
      @player0.valid_attack_pair_callback,
      @player1.valid_attack_pair_callback
    )
    @player0.set_attack_pair!(@input_manager.answer(0))
    @player1.set_attack_pair!(@input_manager.answer(1))
  end

  def ante!
    current_player_id = 0
    number_of_passes = 0
    while number_of_passes < 2
      passed_this_round = true
      # ugly...
      current_player = current_player_id == 0 ? @player0 : @player1

      # if they can ante, make them. If they don't pass, note that,
      # and enact the ante
      if current_player_can_ante?
        @input_manager.require_single_input!(current_player_id,
          "ante", current_player_ante_callback)
        answer = @input_manager.answer(current_player_id)
        passed_this_round = (answer == "pass")
        current_player.ante!(answer)
      end
      if passed_this_round
        number_of_passes += 1
      else
        number_of_passes = 0
      end
      #toggle the player id between 0 and 1
      current_player_id = current_player_id + 1 % 2
    end
  end

  def character_list
    [Hikaru]
  end
  def character_names
    character_list.map(&:name)
  end

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    {
      :location => @player_locations[player_id]
    }
  end
end
