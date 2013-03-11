require "character"
require "bases"

class Critical < Style
  def initialize
    super("critical", 0, -1, 1)
  end

  def ignore_stun_guard?
    true
  end

  def on_hit!
    {
      "extra_power" => select_from_methods(extra_power_at_range_one: %w(yes no))
    }
  end
end

class Rasping < Style
  def initialize
    super("rasping", 0..1, -1, +1)
  end
  def on_hit!
    {
      "extra_power" => select_from_methods(extra_power_at_range_one: %w(yes no))
    }
  end

  #TODO this needs the other effect!
  def on_damage!
    {
      "heal" => ->(me, inputs) { me.heal_half_damage! }
    }
  end
end

class Merciless < Style
  def initialize
    super("merciless", 0..1, -1, 0)
  end
  flag :damage_on_move_past

  def after_activating!
    {
      "dodge" => ->(me, inputs) { me.dodge_if_dark_force! }
    }
  end
end

class Psycho < Style
  def initialize
    super("psycho", 0, 0, 1)
  end

  def start_of_beat!
    {
      "advance" => ->(me, inputs) { me.advance_until_adjacent! }
    }
  end

  def end_of_beat!
    {
      "repeat_attack" => select_from_methods(spend_token_to_repeat: %w(yes no))
    }
  end
end

class Assassin < Style
  def initialize
    super("assassin", 0, 0, 0)
  end

  def on_hit!
    {
      "retreat" => select_from_methods(retreat: [0,1,2,3,4,5,6])
    }
  end

  def on_damage!
    {
      "stop_movement_next_beat" => select_from_methods(spend_token_to_stop_movement: %w(yes no))
    }
  end
end

class Knives < Base
  def initialize
    super("knives", 1..2, 4, 5)
  end

  flag :wins_ties
  flag :no_stun_at_range_one
end

class DarkForce < Token
  def initialize
    super("darkforce", 0, 0, 3)
  end
  def name_and_effect
    "Dark Force (+3 Priority)"
  end
end

class MillionKnives < Finisher
  def initialize
    super("millionknives", 1..4, 3, 7)
  end

  def on_hit!
    {
      "advance_and_repeat" => ->(me,input) { me.advance_and_repeat! }
    }
  end
end

class LivingNightmare < Finisher
  def initialize
    super("livingnightmare", 1, 3, 2)
  end
  def on_hit!
    {
      "gain_unlimited_tokens" => ->(me,input) { me.unlimited_dark_force_tokens! }
    }
  end
end

class DarkForceAnteBonus < Token
  def initialize
    super("darkforceantebonus", 0, 0, 3)
  end
  def name_and_effect
    "Dark Force (+3 priority)"
  end
end

class DarkForcePowerBonus < Token
  def initialize
    super("darkforcepowerbonus", 0, 3, 0)
  end
  def name_and_effect
    "+3 Power"
  end
end

class RegainDarkForce < Token
  def initialize
    super("regaindarkforce", 0, 0, 0)
  end
  def end_of_beat!
    {
      "regain" => ->(me,inputs) { me.regain_dark_force! }
    }
  end
end

class Heketch < Character
  def self.character_name
    "heketch"
  end
  def initialize *args
    super

    # set up my hand
    @hand << Knives.new
    @hand += [
      Assassin.new,
      Psycho.new,
      Rasping.new,
      Merciless.new,
      Critical.new
    ]
    @dark_force = true
    @bonuses = []
  end

  def has_dark_force?
    @dark_force || @unlimited_dark_force
  end

  def finishers
    #[MillionKnives.new, LivingNightmare.new]
    [MillionKnives.new, LivingNightmare.new]
  end

  def effect_sources
    sources = super
    sources += @bonuses
    sources << RegainDarkForce.new if distance > 2
    sources
  end

  def current_effects
    super + @bonuses.map(&:name_and_effect)
  end

  def ante_options
    opts = super
    opts << "dark_force" if has_dark_force?
    opts
  end
  def token_pool
    pool = []
    pool << "Dark Force (Teleport, +3 Priority)" if has_dark_force?
    pool
  end

  def ante!(choice)
    if choice == "pass"
      log_me!("passes.")
      return
    end
    return if super
    log_me!("antes a Dark Force token.")
    @dark_force = false
    select_from_methods(teleport_to: [@opponent.position-1, @opponent.position+1]).call(self, @input_manager)
  end

  def ante?(choice)
    return true if choice == "pass"
    return true if super
    return true if @dark_force
  end

  def valid_answer_for_dark_force?(choice)
    return true if choice == "yes" && has_dark_force?
    return true if choice == "no"
  end

  def extra_power_at_range_one?(choice)
    valid_answer_for_dark_force?(choice)
  end

  def spend_token_to_repeat?(choice)
    valid_answer_for_dark_force?(choice)
  end

  def spend_token_to_stop_movement?(choice)
    valid_answer_for_dark_force?(choice)
  end

  def extra_power_at_range_one!(choice)
    return if choice == "no"
    @bonuses << DarkForcePowerBonus.new#Token.new("Dark force power bonus", 0, 3, 0)
    @dark_force = false
  end

  def spend_token_to_repeat!(choice)
    return if choice == "no"
    @dark_force = false
    execute_attack!
  end

  def spend_token_to_stop_movement!(choice)
    return if choice == "no"
    @dark_force = false
    @stop_all_opponent_movement_next_turn = true
  end

  def can_stun?
    return false if (distance == 1) && flag?(:no_stun_at_range_one)
    super
  end

  def dodge_if_dark_force!
    @merciless_dodge = has_dark_force?
  end

  def blocked_spaces
    return (0..6).to_a if (@stop_all_opponent_movement || @merciless_stop_movement)
    []
  end

  def recycle!
    @merciless_dodge = false
    @merciless_stop_movement
    @bonuse = []
    @stop_all_opponent_movement = @stop_all_opponent_movement_next_turn
    @stop_all_opponent_movement_next_turn = false
    super
  end

  def dodges?
    super || @merciless_dodge
  end

  def advance_until_adjacent!
    if distance > 1
      advance!(distance)
    end
  end

  def pass_by!
    if flag? :damage_on_move_past
      opponent.lose_life!(2)
      @merciless_stop_movement = true
    end
  end

  def regain_dark_force!
    log_me!("regains a dark force token...")
    @dark_force = true
  end

  def advance_and_repeat!
    starting_position = @position
    advance!(1)
    if @position != starting_position && distance > 1
      execute_attack!
    end
  end

  def unlimited_dark_force_tokens!
    @unlimited_dark_force = true
  end

  def heal_half_damage!
    life_to_gain = (@damage_dealt_by_this_attack - (@damage_dealt_by_this_attack/2))
    log_me!("Gained #{life_to_gain}")
    @life += life_to_gain
  end
end
