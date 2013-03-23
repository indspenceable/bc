require "hikaru"
require "cadenza"
require 'khadath'
require 'rukyuk'
require 'hepzibah'
require 'heketch'
require 'zaamassal'
require 'kehrolyn'

# given a hash from methods to possible aruments prompt the user to select a
# valid combination.
# * If none are possible, do nothing.
# * if only one is possible, do that.
# * if more than one are possible, prompt the user to choose one of the possible
#     ones.
MOVEMENT_METHODS = [
  :advance, :retreat, :pull, :push, :teleport_to, :teleport_opponent_to,
  :set_trap_in_range, :set_trap
]
def select_from_methods(options)
  return select_from_movement_methods(options) if options.keys.all?{|k| MOVEMENT_METHODS.include?(k)}
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
      input.require_single_input!(me.player_id, "select_from:#{option_names}", ->(text) {
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

def select_from_movement_methods(options)
  option_list = []
  options.each do |method, arg_options|
    arg_options.each do |arg_option|
      option_list << [method, arg_option]
    end
  end
  ->(me, input) do
    valid_options = {}
    option_list.each do |method, arg|
      confirmation_method = "#{method}?"
      result = me.send(confirmation_method, arg)
      # The first option that goes to a space - use that one
      valid_options[result] ||= [method.to_s, arg.to_s] if result
    end

    return if valid_options.empty?
    ans = nil
    # ask them for input only if theres more than one valid option.
    if valid_options.count > 1
      option_names = valid_options.keys.map{|k| "<#{k}>"}.join('')
      # ask them for the option number they want to do
      input.require_single_input!(me.player_id, "select_from_movement:#{option_names}", ->(text) {
        valid_options.key?(Integer(text))
      })
      ans = input.answer(me.player_id)
      method, argument = valid_options[Integer(ans)]
    else
      method, argument = valid_options.values.first
    end
    # do that option number
    me.send("#{method}!", argument)
    return ans
  end
end

class GamePlay
  attr_accessor :active_player, :reactive_player
  def characters
    @players
  end

  def initialize(starting_player, player_names, inputs=[], idx=nil)
    @starting_player = starting_player
    @player_names = player_names
    @valid_inputs_thus_far = inputs
    setup_game!(@valid_inputs_thus_far, idx)
  end

  def valid_inputs
    @valid_inputs_thus_far
  end

  attr_reader :winner, :loser, :tie

  def setup_game!(inputs, idx=nil)
    @input_manager = InputManager.new(inputs)
    @events = EventManager.new(idx)
    @player_locations = {
      0 => 1,
      1 => 5
    }
    @last_active_player_id = @starting_player
    @active = true
    cause, winner = catch :halt do
      play_15_turns!
      return resolve_timeout!
    end
    if cause == :ko || cause == :concede
      resolve_game!(cause, winner)
    end
  end

  def resolve_timeout!
    @active = false
    @events.log! "Time up!"
    winner = loser = nil
    if @players[0].life > @players[1].life
      winner = @players[0]
      loser = @players[1]
    elsif @players[0].life < @players[1].life
      winner = @players[1]
      loser = @players[0]
    else
      @tie = true
      @events.log! "Tie at #{@players[0].life}!"
      return
    end
    @events.log! "#{winner.player_name} wins at #{winner.life} to #{loser.life}"
    @winner = winner.player_name
    @loser = loser.player_name
    return
  end

  def resolve_game!(cause, winner)
    @active = false
    @winner = @players[winner].player_name
    @loser = @players[(winner+1)%2].player_name
    @events.log! "#{@loser} concedes the game." if cause == :concede
    @events.log! "#{@winner} wins!"
    return
  end

  def play_15_turns!
    select_characters!
    select_discards_and_finishers!
    15.times do |round_number|
      @round_number = round_number + 1 # 1 based
      select_attack_pairs!
      ante!
      reveal!
      next @players.each(&:recycle!) if handle_pulses!
      # if either player runs out of cards, go to the next turn
      if handle_clashes! == :no_cards
        @events.log!("A player ran out of cards. Turn is cycling.")
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
      :events => @events.to_a,
      :players => [
        player_info_for(0, player_id),
        player_info_for(1, player_id)
      ],
      :input_number => @input_manager.input_counter,
      :current_phase => "select_character",
      :current_beat => @round_number,
      :winner => @winner,
      :active => @active,
      :can_undo => can_undo?(player_id)
    }
  end

  def active?
    !!@active
  end
  def can_undo?(player_id)
    @input_manager.can_undo.include?(player_id)
  end

  private

  # phases of the game
  def select_characters!
    #character selection
    @input_manager.require_multi_input!(
      ["select_character", ->(text) { GamePlay.character_names.include?(text) }],
      ["select_character", ->(text) { GamePlay.character_names.include?(text) }],
    )

    @events.log!("#{@player_names[0]} chooses: #{@input_manager.answer(0)}")
    @events.log!("#{@player_names[1]} chooses: #{@input_manager.answer(1)}")

    @players = [nil, nil]
    @players[0] = GamePlay.character_list[
      GamePlay.character_names.index @input_manager.answer(0)].new(
        0,
        @player_names[0],
        @input_manager,
        @events)
    @players[1] = GamePlay.character_list[
      GamePlay.character_names.index @input_manager.answer(1)].new(
        1,
        @player_names[1],
        @input_manager,
        @events)

    @players[0].opponent = @players[1]
    @players[1].opponent = @players[0]
  end
  def select_discards_and_finishers!
    p0a0 = p1a0 = nil
    finisher_names = @players.map{|p| p.finishers.map(&:name)}
    finisher_options = finisher_names.map{|f| f.map{|n| "<#{n}>"}.join('')}
    @input_manager.require_multi_input!(
      ["attack_pair_discard_one", @players[0].valid_attack_pair_callback(nil),  ->(a) {p0a0 = a; @players[0].set_initial_discard2(a)}],
      ["attack_pair_discard_one", @players[1].valid_attack_pair_callback(nil),  ->(a) {p1a0 = a; @players[1].set_initial_discard2(a)}],
      ["attack_pair_discard_two", @players[0].valid_attack_pair_callback(p0a0), ->(a) {@players[0].set_initial_discard1(a)}],
      ["attack_pair_discard_two", @players[1].valid_attack_pair_callback(p1a0), ->(a) {@players[1].set_initial_discard1(a)}],
      ["select_from:#{finisher_options[0]}", ->(i){finisher_names[0].include?(i)}, ->(a) {@players[0].select_finisher!(a)}],
      ["select_from:#{finisher_options[1]}", ->(i){finisher_names[1].include?(i)}, ->(a) {@players[1].select_finisher!(a)}],
    )
    @players[0].set_initial_discards!
    @players[1].set_initial_discards!

    # @events.log!("Select initial discards", "#{@player_names[0]} discards #{p0a0} and #{p0a1}.", "#{@player_names[1]} discards #{p1a0} and #{p1a1}.")
  end

  def select_attack_pairs!
    @input_manager.require_multi_input!(
      ["attack_pair_select", @players[0].valid_attack_pair_callback, ->(a) {@players[0].set_attack_pair!(a)}],
      ["attack_pair_select", @players[1].valid_attack_pair_callback, ->(a) {@players[1].set_attack_pair!(a)}]
    )
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
        # @events.log!("Ante", "Player #{current_player_id} antes #{answer}")
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
    @events.log!("Ante phase done")
  end

  def reveal!
    @input_manager.stop_undos!
    # did they BOTH cancel?
    if @players[0].cancelled? && @players[1].cancelled?
      @events.log!("Both players reveal cancel!")
      @players[0].cancel!
      @players[1].cancel!
      select_attack_pairs!
    elsif @players[0].cancelled?
      @players[1].reveal!
      @events.log!("player 0 cancels!")
      @players[0].cancel!
      @input_manager.require_single_input!(
        0,
        "attack_pair_select",
        @players[0].valid_attack_pair_callback
      )
      @players[0].set_attack_pair!(@input_manager.answer(0))
      @players[0].reveal!
    elsif @players[1].cancelled?
      @players[0].reveal!
      @events.log!("player 1 cancels!")
      @players[1].cancel!
      @input_manager.require_single_input!(
        1,
        "attack_pair_select",
        @players[1].valid_attack_pair_callback
      )
      @players[1].set_attack_pair!(@input_manager.answer(1))
      @players[1].reveal!
    else
      @players.each(&:reveal!)
    end
  end

  def handle_pulses!
    if @players.all?(&:pulsed?)
      @events.log!("both players pulsed")
      true
    elsif @players[0].pulsed?
      @players[0].pulse!
      true
    elsif @players[1].pulsed?
      @players[1].pulse!
      true
    else
      false
    end
  end

  def passive_abilities!
    @players.each(&:passive_abilities!)
  end

  def priority_accounting_for_tiebreakers(pl)
    p = pl.priority
    p += 0.1 if pl.flag? :wins_ties
    p += 0.3 if pl.played_finisher?
    p -= 0.1 if pl.flag? :loses_ties
    p
  end

  def handle_clashes!
    while priority_accounting_for_tiebreakers(@players[0]) == priority_accounting_for_tiebreakers(@players[1])
      # If finishers tie
      if @players.all?(&:played_finisher?) &&
        # cancel them
        @players.each(&:cancel_finisher!)
        select_attack_pairs!
        #reveal attack pairs.
        reveal!
        #check priorities again.
        next
      end

      @events.log!("Clash at #{@players[0].priority} priority")
      @players.each do |p|
        p.clash!
      end
      return :no_cards if (@players[0].no_bases? || @players[1].no_bases?)
      @input_manager.require_multi_input!(
        ["select_base_clash", @players[0].base_options_callback],
        ["select_base_clash", @players[1].base_options_callback]
      )
      @players[0].select_new_base!(@input_manager.answer(0))
      @players[1].select_new_base!(@input_manager.answer(1))

      @events.log!("Resolve Clash " + @players.each_with_index.map do |p, i|
        "#{@player_names[i]} reveals #{p.current_base_name}"
      @input_manager.stop_undos!
      end.join(' / '))
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
    if priority_accounting_for_tiebreakers(@players[0]) > priority_accounting_for_tiebreakers(@players[1])
      @active_player, @reactive_player = @players[0], @players[1]
    else
      @active_player, @reactive_player = @players[1], @players[0]
    end
    #some characters care if they are active...
    @events.log!("#{active_player.player_name} is the active player (#{@active_player.priority} / #{@reactive_player.priority})")
    @last_active_player_id = @active_player.player_id
    @active_player.is_active!
    @reactive_player.is_reactive!
  end

  def start_of_beat!
    @events.log!("Start of beat #{@round_number}")
    @active_player.start_of_beat!
    @reactive_player.start_of_beat!
  end
  def end_of_beat!
    @events.log!("End of beat #{@round_number}")
    @active_player.end_of_beat!
    @reactive_player.end_of_beat!
  end
  def recycle!
    @active_player.recycle!
    @reactive_player.recycle!
  end

  def activate!(current, opponent)
    unless current.stunned?
      current.execute_attack!
    else @events.log!("#{current.player_name} is stunned!")
    end
  end

  def self.character_list
    [Hikaru, Cadenza, Khadath, Rukyuk, Heketch, Zaamassal, Hepzibah, Kehrolyn]
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
      :special_action => @players[player_id].special_action_name(as_seen_by_id),
      :token_pool => @players[player_id].token_pool_descriptors,
      :current_effects => @players[player_id].current_effect_descriptors,
      :extra_data => @players[player_id].extra_data,
      :discard1 => @players[player_id].discard1(as_seen_by_id),
      :discard2 => @players[player_id].discard2(as_seen_by_id),
      :character_name => @players[player_id].name,
      :finisher_name => @players[player_id].finisher_name(as_seen_by_id),
      :special_action_available => @players[player_id].special_action_available,
    }
  end
end
