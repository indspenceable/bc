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
    catch :input_required do
      #character selection
      @input_manager.require_multi_input!("select_character",
        ->(text) { character_list.include?(text) },
        ->(text) { character_list.include?(text) }
      )
      # for now, just consume input.
      @player0 = @input_manager.answer(0)# player_class_by_name(@input_manager.answer(0)).new
      @player1 = @input_manager.answer(1)# player_class_by_name(@input_manager.answer(1)).new


      # select_discards
      @input_manager.require_multi_input!("select_discards",
        ->(text) { text =~ /[a-z]*_[a-z]*;[a-z]*_[a-z]*/},
        ->(text) { text =~ /[a-z]*_[a-z]*;[a-z]*_[a-z]*/}
      )

      @input_manager.require_multi_input("select_attack_pairs",
        ->(text) { text =~ /[a-z]*_[a-z]*/ },
        ->(text) { text =~ /[a-z]*_[a-z]*/ }
      )
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
      0 => player_info_for(0, player_id),
      1 => player_info_for(1, player_id),
      :current_phase => "select_character"
    }
  end

  private

  def character_list
    ["hikaru"]
  end

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    nil
  end
end
