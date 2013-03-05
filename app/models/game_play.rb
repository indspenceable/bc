require "hikaru"
require "cadenza"
require 'khadath'
require 'rukyuk'

# given a hash from methods to possible aruments prompt the user to select a
# valid combination.
# * If none are possible, do nothing.
# * if only one is possible, do that.
# * if more than one are possible, prompt the user to choose one of the possible
#     ones.
def select_from_methods(selection_name=nil, options)
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
    ans = nil

    # ask them for input only if theres more than one valid option.
    if valid_options.count > 1
      option_names = valid_options.map{|k,v| "<#{k}##{v}>"}.join('')
      # ask them for the option number they want to do
      input.require_single_input!(me.player_id, selection_name || "select_from:#{option_names}", ->(text) {
        valid_options.include?(text.split('#'))
      })
      ans = input.answer(me.player_id)
      method, argument = ans.split('#')
    else
      ans = valid_options.first.join('#')
      method, argument = valid_options.first
    end
    # do that option number
    me.send("#{method}!", argument)
    return ans
  end
end

class GamePlay
  # Input manager manages input.
  class InputManager
    attr_reader :input_counter
    def initialize(input_buffer)
      @required_input = {}
      @input_buffer = Hash.new{|h, k| h[k] = []}
      input_buffer.each do |player_id, str|
        @input_buffer[player_id] << str
      end
      @input_counter = 0
    end
    def require_single_input!(player_id, input_string, validator)
      raise "Didn't answer previous question" if input_required?
      @input_counter+=1
      @answers = {}
      @required_input = {
        player_id => [input_string, validator]
      }
      answer_inputs!
    end
    def require_multi_input!(input_string, *validators)
      raise "Didn't answer previous question" if input_required?
      @input_counter+=1
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
      raise "Invalid answer \"#{string}\" to #{@required_input[player_id].first}" unless validator.call(string)
      @required_input.delete(player_id)
      @answers[player_id] = string.downcase
    end
    def input_required?
      @required_input.keys.any?{|k| !@answers.key?(k) }
    end
  end

  attr_accessor :active_player, :reactive_player
  def characters
    @players
  end

  def initialize(starting_player, player_names, inputs=[])
    @starting_player = starting_player
    @player_names = player_names
    @valid_inputs_thus_far = inputs
    setup_game!(@valid_inputs_thus_far)
  end

  def valid_inputs
    @valid_inputs_thus_far
  end

  def setup_game!(inputs)
    @input_manager = InputManager.new(inputs)
    @events = []
    @player_locations = {
      0 => 1,
      1 => 5
    }
    @last_active_player_id = @starting_player
    @active = true
    catch :input_required do
      catch :ko do
        select_characters!
        select_discards!
        15.times do |round_number|
          @round_number = round_number + 1 # 1 based
          select_attack_pairs!
          ante!
          reveal!
          # if either player runs out of cards, go to the next turn
          if handle_clashes! == :no_cards
            log_event!("A player ran out of cards. Turn is cycling.")
            regain_cards!
            next
          end
          regain_bases!
          determine_active_player!
          passive_abilities!
          start_of_beat!
          activate!(@active_player, @reactive_player)
          activate!(@reactive_player, @active_player)
          end_of_beat!
          recycle!
        end
        # if they get here, the game timed out
        @active = false
        # TODO - set winner
        return
      end
      # if they get here, one of the characters got KO'd
      @active = false
      # TODO set winner
      return
    end
    # this means there wasn't enough input; thus, the game isn't over.
  end

  def input!(player_id, str)
    setup_game!(@valid_inputs_thus_far + [[Integer(player_id), str]])
    @valid_inputs_thus_far = @valid_inputs_thus_far + [[Integer(player_id), str]]
    required_input
  end
  def rollback!
    @valid_inputs_thus_far.pop
    setup_game!(@valid_inputs_thus_far)
  end
  def retry!
    setup_game!(@valid_inputs_thus_far)
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
      :input_number => @input_manager.input_counter,
      :current_phase => "select_character",
      :current_beat => @round_number,
      :winner => @winner
    }
  end

  def active?
    !!@active
  end

  private

  # log events to the game's event log
  #    phase - string
  #    *events - list of event strings to be separated by '; '
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
      ->(text) { GamePlay.character_names.include?(text) },
      ->(text) { GamePlay.character_names.include?(text) }
    )

    log_event!("#{@player_names[0]} chooses: #{@input_manager.answer(0)}")
    log_event!("#{@player_names[1]} chooses: #{@input_manager.answer(1)}")

    @players = [nil, nil]
    # for now, just consume input.
    event_logger = ->(*inputs) do
      log_event!(inputs)
    end
    @players[0] = GamePlay.character_list[
      GamePlay.character_names.index @input_manager.answer(0)].new(
        0,
        @player_names[0],
        @input_manager,
        @events,
        event_logger)
    @players[1] = GamePlay.character_list[
      GamePlay.character_names.index @input_manager.answer(1)].new(
        1,
        @player_names[1],
        @input_manager,
        @events,
        event_logger)

    @players[0].opponent = @players[1]
    @players[1].opponent = @players[0]
  end
  def select_discards!
    # TODO This should allow players to discard both sets of cards at once

    # # select_discards
    # @input_manager.require_multi_input!("select_discards",
    #   # these should shell out to characters individual methods, for roberts
    #   # sake.
    #   @players[0].valid_discard_callback,
    #   @players[1].valid_discard_callback
    # )
    # @players[0].set_initial_discards!(@input_manager.answer(0))
    # @players[1].set_initial_discards!(@input_manager.answer(1))

    @input_manager.require_multi_input!("attack_pair_discard_one",
      @players[0].valid_attack_pair_callback(nil),
      @players[1].valid_attack_pair_callback(nil),
    )
    p0a0 = @input_manager.answer(0)
    p1a0 = @input_manager.answer(1)

    @input_manager.require_multi_input!("attack_pair_discard_two",
      @players[0].valid_attack_pair_callback(p0a0),
      @players[1].valid_attack_pair_callback(p1a0),
    )
    p0a1 = @input_manager.answer(0)
    p1a1 = @input_manager.answer(1)

    @players[0].set_initial_discards!("#{p0a0};#{p0a1}")
    @players[1].set_initial_discards!("#{p1a0};#{p1a1}")

    log_event!("Select initial discards", "#{@player_names[0]} discards #{p0a0} and #{p0a1}.", "#{@player_names[1]} discards #{p1a0} and #{p1a1}.")
  end

  def select_attack_pairs!
    @input_manager.require_multi_input!("attack_pair_select",
      @players[0].valid_attack_pair_callback,
      @players[1].valid_attack_pair_callback
    )
    @players[0].set_attack_pair!(@input_manager.answer(0))
    @players[1].set_attack_pair!(@input_manager.answer(1))
  end

  def ante!
    current_player_id = @last_active_player_id
    number_of_passes = 0
    while number_of_passes < 2
      passed_this_round = true
      # ugly...
      current_player = current_player_id == 0 ? @players[0] : @players[1]

      # if they can ante, make them. If they don't pass, note that,
      # and enact the ante
      # if current_player.can_ante?
      #
      #   They can always ante, they just might not have options other than "pass"
      #
        # @input_manager.require_single_input!(current_player_id,
        #   "ante", current_player.ante_callback)
        # answer = @input_manager.answer(current_player_id)
        answer = select_from_methods(ante: current_player.ante_options).call(current_player, @input_manager)
        #TODO fix so "Player 1 passes" instead of "Player 1 antes pass"
        # log_event!("Ante", "Player #{current_player_id} antes #{answer}")
        passed_this_round = (answer == 'ante#pass')
      # end
      if passed_this_round
        number_of_passes += 1
      else
        number_of_passes = 0
      end
      #toggle the player id between 0 and 1
      current_player_id = (current_player_id + 1) % 2
    end
    log_event!("Ante phase done")
  end

  def reveal!
    @players.each(&:reveal!)
    log_event!("Reveal", "#{@player_names[0]} plays #{@players[0].reveal_attack_pair!}", "#{@player_names[1]} plays #{@players[1].reveal_attack_pair!}")
  end

  def passive_abilities!
    @players.each(&:passive_abilities!)
  end

  def handle_clashes!
    while @players[0].priority == @players[1].priority
      log_event!("Clash at #{@players[0].priority} priority")
      @players.each do |p|
        p.clash!
      end
      return :no_cards if (@players[0].no_bases? || @players[1].no_bases?)
      @input_manager.require_multi_input!("select_base_clash",
        @players[0].base_options_callback,
        @players[1].base_options_callback
      )
      @players[0].select_new_base!(@input_manager.answer(0))
      @players[1].select_new_base!(@input_manager.answer(1))

      log_event!("Resolve Clash", @players.each_with_index.map do |p, i|
        "#{@player_names[i]} reveals #{p.current_base_name}"
      end)
    end
  end

  def regain_bases!
    @players.each do |p|
      p.regain_bases!
    end
  end
  def regain_cards!
    @players.each do |p|
      p.regain_cards!
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
    log_event!("#{active_player.player_name} is the active player (#{@active_player.priority} / #{@reactive_player.priority})")
    @last_active_player_id = @active_player.player_id
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
        log_event!("#{current.player_name} hits #{opponent.player_name} for
          #{damage_dealt} damage!")
        if damage_dealt > 0
          current.on_damage!
        end
      else
        log_event!("#{current.player_name} misses!")
      end
      current.after_activating!
    else log_event!("#{current.player_name} is stunned!")
    end
  end

  def self.character_list
    [Hikaru, Cadenza, Khadath, Rukyuk]
  end
  def self.character_names
    character_list.map(&:character_name)
  end

  # returns a hash of player info, for that player id.
  # this adds more information if player_id and as_seen_by_id match
  def player_info_for(player_id, as_seen_by_id)
    {
      :life => @players[player_id].life,
      :location => @players[player_id].position,
      :stunned => @players[player_id].stunned?,
      :bases => @players[player_id].bases(as_seen_by_id).map(&:name),
      :styles => @players[player_id].styles(as_seen_by_id).map(&:name),
      :current_base => @players[player_id].current_base_name(as_seen_by_id),
      :current_style => @players[player_id].current_style_name(as_seen_by_id),
      :token_pool => @players[player_id].token_pool,
      :current_effects => @players[player_id].current_effects,
      :extra_data => @players[player_id].extra_data,
      :discard1 => @players[player_id].discard1,
      :discard2 => @players[player_id].discard2,
    }
  end
end
