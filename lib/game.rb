class Card
  attr_reader :name, :power, :priority, :range
  def initialize name, range, power, priority
    @name = name
    @power = power
    @priority = priority
    @range = range
  end
end

class Character; end
class Hikaru < Character
  def self.name
    "hikaru"
  end
  def initialize my_id, inputs, events
    @my_id = my_id
    @inputs = inputs
    @events = events

    # set up my hand
    # %w(grasp drive strike shot burst dash palmstrike)
    @bases = [
      Card.new("grasp",      1, 2, 5),
      Card.new("drive",      1, 3, 4),
      Card.new("strike",     1, 4, 3),
      Card.new("shot",    1..4  3, 2),
      Card.new("burst",   2..3, 3, 1),
      #Card.new("dash", 9, :na, :na)
      Card.new("palmstrike", 1, 2, 5),
    ]
    # %(trance focused geomantic sweeping advancing)
    @styles = [
      Card.new("trance", 0..1, 0, 0),
      Card.new("focused",   0, 0, 1),
      Card.new("geomantic", 0, 1, 0),
      Card.new("sweeping",  0,-1, 3),
      Card.new("advancing", 0, 1, 1),
    ]
    @token_pool = %w(earth wind fire water)
    @token_discard = []
    @current_tokens = []
  end

  def set_initial_discards!(choice)
    choice =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
    s1,b1,s2,b2 = $1, $2, $3, $4
    @discard1 = [s1, b1]
    @discard2 = [s2, b2]
    @bases.delete(b1)
    @bases.delete(b2)
    @styles.discard(s1)
    @styles.discard(s2)
  end

  def can_ante?
    @token_pool.any?
  end

  def ante!(choice)
    @current_tokens << @token_pool.delete(choice)
  end

  def start_of_beat
  end

  # input callbacks. These check the validity of input that the player does.
  # is this the best design? I dunno. It does make it easy for us to identify
  # when theres an error due to invalid input, though.

  # this should probably live in character.
  def valid_discard_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
      s1,b1,s2,b2 = $1, $2, $3, $4
      bases.include?(b1) && bases.include?(b2) && b1 != b2 &&
      styles.include?(s1) && styles.include?(s2) && s1 != s2
    end
  end
  def valid_attack_pair_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*)/
      bases.include?($2) && styles.include?($1)
    end
  end
  def ante_callback
    ->(text) do
      (@token_pool + ["pass"]).include?($1)
    end
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
    @events = []
    @player_locations = {
      0 => 1,
      1 => 5,
    }
    catch :input_required do
      select_characters!
      select_discards!
      15.times do |round_number|
        @round_number = round_number + 1 # 1 based
        select_attack_pairs!
        ante!
        reveal!
        # if either player runs out of cards, go to the next turn
        next if handle_clashes! == :no_cards
        determine_active_player!
        start_of_beat!
        activate!(@active_player, @reactive_player)
        activate!(@reactive_player, @active_player)
        end_of_beat!
        recycle!
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
    @player0 =
      character_list[character_names.index @input_manager.answer(0)].new(
        0,
        @input_manager,
        @events)
    @player1 =
      character_list[character_names.index @input_manager.answer(1)].new(
        1,
        @input_manager,
        @events)
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
      if current_player.can_ante?
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

  def reveal!
    @player0.reveal_attack_pair!
    @player1.reveal_attack_pair!
  end

  def handle_clashes!
    while @player0.priority == @player1.priority
      return :no_cards if @player0.no_cards? || @player1.no_cards?
      # Mark an event as a clash!
      @input_manager.require_multi_input!("select_new_base",
        @player0.base_options_callback,
        @player1.base_options_callback
      )
      @player0.new_base!(@input_manager.answers(0))
      @player1.new_base!(@input_manager.answers(1))
    end
  end

  def determine_active_player!
    # at this point, we know someone won priority
    if @player0.priority > @player1.priority
      @active_player, @reactive_player = @player0, @player1
    else
      @active_player, @reactive_player = @player1, @player0
    end
    #some characters care if they are active...
    @active_player.is_active!
    @reactive_player.is_reactive!
  end

  def start_of_beat!
    @active_player.start_of_beat!
    @reactive_player.start_of_beat!
  end
  def end_of_beat!
    @active_player.end_of_beat!
    @reactive_player.end_of_beat!
  end
  def recycle!
    @active_player.recycle!
    @reactive_player.recycle!
  end

  def activate!(current, opponent)
    unless current.stunned?
      current.before_activating!
      # are they in range?
      if current.in_range?(opponent)
        current.on_hit!
        damage_dealt = opponent.take_hit!(current.power)
        if damage_dealt > 0
          current.on_damage!
        end
      end
      current.after_activating!
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
