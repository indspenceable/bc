
require_relative "hikaru"

#MAGIC METHOD
def select_from_methods(selection_name, options)
  option_list = []
  options.each do |method, arg_options|
    arg_options.each do |arg_option|
      option_list << [method, arg_option]
    end
  end
  ->(me, input) do
    valid_options = []
    option_list.each do |method, arg|
      confirmation_method = "#{method}?"
      valid_options << [method.to_s, arg.to_s] if me.send(confirmation_method, arg)
    end

    return if valid_options.empty?

    # ask them for input only if theres more than one valid option.
    if valid_options.count > 1
      option_names = valid_options.map{|k,v| "#{k}_#{v}"}.join(';')
      # ask them for the option number they want to do
      input.require_single_input!(me.character_id, selection_name || option_names, ->(text) {
        valid_options.include?(text.split('_'))
      })
      method, argument = input.answer(me.character_id).split('_')
    else
      method, argument = valid_options.first
    end
    # do that option number
    me.send("#{method}!", argument)
  end
end

#MAGIC MIKE
def select_from_options(selection_name, options)
  #lamda will take in the calling object and the inputmanager
  ->(me, input) do
    #figure out which of the options are valid
    valid_options = []
    options.each do |option|
      #uses the selection_name? as a validator of input
      validation_method = "#{selection_name}?"
      valid_options << option.to_s if me.send(validation_method, option)
    end

    return if valid_options.empty?

    # ask them for input only if theres more than one valid option.
    if valid_options.count > 1
      option_names = valid_options.join(';')
      #Get the option from the user
      input.require_single_input!(me.character_id, selection_name || option_names, ->(text) {
                                    valid_options.include?(text)
                                  })
      # returns the answer selected by the user (after validation)
      input.answer(me.character_id)
    else
      # or just returns the only valid option
      selection = valid_options.first
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
      if input_required?
        @input_buffer.each do |k,v|
          raise "#{k} sent input (#{v}) when it wasn't needed." if v.any?
        end
        throw :input_required
      end
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
      1 => 5
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
    setup_game!(@valid_inputs_thus_far + [[Integer(player_id), str]])
    @valid_inputs_thus_far = @valid_inputs_thus_far + [[Integer(player_id), str]]
    required_input
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
    return {:events => []} unless @players
    {
      :events => @events,
      :players => [
        player_info_for(0, player_id),
        player_info_for(1, player_id)
      ],
      :current_phase => "select_character"
    }
  end

  private

  # log events to the game's event log
  #    phase - string
  #    *events - list of event strings to be separated by ';'
  def log_event!(phase, *events)
    if (events.empty?)
      @events << phase
      return @events
    end
    @events << (phase + ': ' + events.join('; '))
    return @events
  end


  # phases of the game
  def select_characters!
    #character selection
    @input_manager.require_multi_input!("select_character",
      ->(text) { Game.character_names.include?(text) },
      ->(text) { Game.character_names.include?(text) }
    )
    @players = [nil, nil]
    # for now, just consume input.
    @players[0] = Game.character_list[
      Game.character_names.index @input_manager.answer(0)].new(
        0,
        @input_manager,
        @events)
    @players[1] = Game.character_list[
      Game.character_names.index @input_manager.answer(1)].new(
        1,
        @input_manager,
        @events)

    @players[0].opponent = @players[1]
    @players[1].opponent = @players[0]
  end
  def select_discards!
    # # select_discards
    # @input_manager.require_multi_input!("select_discards",
    #   # these should shell out to characters individual methods, for roberts
    #   # sake.
    #   @players[0].valid_discard_callback,
    #   @players[1].valid_discard_callback
    # )
    # @players[0].set_initial_discards!(@input_manager.answer(0))
    # @players[1].set_initial_discards!(@input_manager.answer(1))

    @input_manager.require_multi_input!("select_attack_pairs",
      @players[0].valid_attack_pair_callback,
      @players[1].valid_attack_pair_callback,
    )
    p0a0 = @input_manager.answer(0)
    p1a0 = @input_manager.answer(1)
    @input_manager.require_multi_input!("select_attack_pairs",
      @players[0].valid_attack_pair_callback,
      @players[1].valid_attack_pair_callback,
    )
    p0a1 = @input_manager.answer(0)
    p1a1 = @input_manager.answer(1)

    @players[0].set_initial_discards!("#{p0a0};#{p0a1}")
    @players[1].set_initial_discards!("#{p1a0};#{p1a1}")
  end

  def select_attack_pairs!
    @input_manager.require_multi_input!("select_attack_pairs",
      @players[0].valid_attack_pair_callback,
      @players[1].valid_attack_pair_callback
    )
    @players[0].set_attack_pair!(@input_manager.answer(0))
    @players[1].set_attack_pair!(@input_manager.answer(1))
  end

  def ante!
    # TODO implement previous active player rule
    current_player_id = 0
    number_of_passes = 0
    while number_of_passes < 2
      passed_this_round = true
      # ugly...
      current_player = current_player_id == 0 ? @players[0] : @players[1]

      # if they can ante, make them. If they don't pass, note that,
      # and enact the ante
      if current_player.can_ante?
        @input_manager.require_single_input!(current_player_id,
          "ante", current_player.ante_callback)
        answer = @input_manager.answer(current_player_id)
        #TODO fix so "Player 1 passes" instead of "Player 1 antes pass"
        log_event!("Ante", "Player #{current_player_id} antes #{answer}")
        passed_this_round = (answer == "pass")
        current_player.ante!(answer)
      end
      if passed_this_round
        number_of_passes += 1
      else
        number_of_passes = 0
      end
      #toggle the player id between 0 and 1
      current_player_id = (current_player_id + 1) % 2
    end
    log_event!("Ante", "done")
  end

  def reveal!
    log_event!("Reveal", "Player 0 plays #{@players[0].reveal_attack_pair!}", "Player 1 plays #{@players[1].reveal_attack_pair!}")
  end

  def handle_clashes!
    while @players[0].priority == @players[1].priority
      log_event!("Clash!!")
      return :no_cards if (@players[0].no_cards? || @players[1].no_cards?)
      @input_manager.require_multi_input!("select_new_base",
        @players[0].base_options_callback,
        @players[1].base_options_callback
      )
      @players[0].select_new_base!(@input_manager.answer(0))
      @players[1].select_new_base!(@input_manager.answer(1))
      reveal!
    end
  end

  def determine_active_player!
    # at this point, we know someone won priority
    if @players[0].priority > @players[1].priority
      @active_player, @reactive_player = @players[0], @players[1]
    else
      @active_player, @reactive_player = @players[1], @players[0]
    end
    #some characters care if they are active...
    log_event!("Player #{@active_player.character_id} is the active player")
    @active_player.is_active!
    @reactive_player.is_reactive!
  end

  def start_of_beat!
    log_event!("Start of beat #{@round_number}")
    @active_player.start_of_beat!
    @reactive_player.start_of_beat!
  end
  def end_of_beat!
    log_event!("End of beat #{@round_number}")
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
      if current.in_range?

        current.on_hit!
        damage_dealt = opponent.take_hit!(current.power)
        log_event!("Player #{current.character_id} hits Player #{opponent.character_id} for 
          #{damage_dealt} damage!")
        if damage_dealt > 0
          current.on_damage!
        end
      else
        log_event!("Player #{current.character_id} misses!")
      end
      current.after_activating!
    else log_event!("Player #{current.character_id} is stunned!")
    end
  end

  def self.character_list
    [Hikaru]
  end
  def self.character_names
    character_list.map(&:character_name)
  end

  # def hand_s(hand)
  #   hand_s = []
  #   hand.each do |card|
  #     hand_s << card.name
  #   end
  #   hand_s
  # end

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    {
      :location => @players[player_id].position,
      #:hand => hand_s(@players[player_id].hand)
      :hand => ->(hand) {
        hand_s = []
        hand.each do |card|
          hand_s << card.name
        end
        hand_s
      }.(@players[player_id].hand),
      :stunned => @players[player_id].stunned?
    }
  end
end
