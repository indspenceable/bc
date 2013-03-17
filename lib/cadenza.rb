require "character"
require "bases"

class Battery < Style
  def initialize
    super("battery", 0, 1, -1)
  end
  def end_of_beat!
    {
      "charge" => ->(me, inpt) {
        me.charge_battery!
      }
    }
  end
end

class Clockwork < Style
  def initialize
    super("clockwork", 0, 3, -3)
  end
  def soak
    3
  end
end

class Hydraulic < Style
  def initialize
    super("hydraulic", 0, 2, -1)
  end
  def soak
    1
  end
  def before_activating!
    {
      "advance" => select_from_methods(advance: [1])
    }
  end
end

class Mechanical < Style
  def initialize
    super("mechanical", 0, 2, -2)
  end

  def end_of_beat!
    {
      "advance" => select_from_methods(advance: [0,1,2,3])
    }
  end
end
class Grapnel < Style
  def initialize
    super("grapnel", 2..4, 0, 0)
  end

  def on_hit!
    {
      "pull" => select_from_methods(pull: [0,1,2,3])
    }
  end
end

class Press < Base
  def initialize
    super("press", 1..2, 1, 0)
  end
  def stun_guard
    6
  end

  flag :bonus_power_per_damage_taken
end

class RocketPress < Finisher
  def initialize
    super("rocketpress", 1, 8, 0)
  end
  def soak
    3
  end
  def stun_immunity?
    true
  end
  def before_activating!
    {
      "advance" => select_from_methods(advance: [2,3,4,5,6])
    }
  end
end

class FeedbackField < Finisher
  def initialize
    super("feedbackfield", 1..2, 1, 0)
  end
  def soak
    5
  end
  def on_hit!
    {
      "feedback_bonus_power" => ->(me, inputs) { me.bonus_power_for_feedback_field! }
    }
  end
end

#TODO this should be implemented as "Generic Bonus"... Or We don't even need to subclass it?
class FeedbackFieldBonus < Token
  def initialize(pwr)
    super("feedbackfieldpowerbonus", 0, pwr, 0)
  end
end

class Cadenza < Character
  def initialize *args
    super
    @hand << Press.new
    @hand += [
      Battery.new,
      Clockwork.new,
      Mechanical.new,
      Grapnel.new,
      Hydraulic.new,
    ]
    @token_count = 3
    @bonuses = []
  end
  def self.character_name
    'cadenza'
  end

  def finishers
    [RocketPress.new, FeedbackField.new]
  end

  def effect_sources
    super + @bonuses
  end

  def charge_battery!
    @battery_charge = true
  end

  def receive_damage!(damage)
    super
    if damage > 0 && @token_count > 0 && exceeds_stun_guard?(damage)
      select_from_methods(iron_body: ['yes', 'pass']).call(self, @input_manager)
    end
  end

  def stun_immunity?
    super || @iron_body_stun_immunity
  end

  def iron_body?(action)
    return true if action == "pass"
    return @token_count > 0
  end
  def iron_body!(action)
    return if action == "pass"
    log_me!("discards an iron body token for infinite stun guard.")
    @token_count -= 1
    @iron_body_stun_guard = true
  end

  def exceeds_stun_guard?(amt)
    return false if @iron_body_stun_guard
    super(amt)
  end

  def power
    #this should be an On hit effect... really.
    if flag? :bonus_power_per_damage_taken
      log_me!("gets #{@damage_taken_this_beat} bonus damage from press!")
      @damage_taken_this_beat + super
    else
      super
    end
  end
  def priority
    (@battery_bonus ? 4 : 0) + super
  end
  def token_pool
    # TODO This is ugly. I feel like we should be using real tokens here and leverage them in the JS
    ([name:"Iron Body"] * @token_count) + super
  end

  #ante-ing iron body tokens
  def ante_options
    (@iron_body_stun_immunity ? [] : ["ironbody"]) + super
  end

  def ante?(action)
    return true if action == "pass"
    return true if super
    return @token_count > 0 && !@iron_body_stun_immunity
  end
  def ante!(action)
    return if action == "pass"
    return if super
    log_me!("antes an iron body token.")
    @token_count -= 1
    @iron_body_stun_immunity = true
  end

  def current_effects
    ary = []
    ary << "Battery (+4 Priority)" if @battery_bonus
    ary << "Press (+#{@damage_taken_this_beat} damage)" if flag? :bonus_power_per_damage_taken && @revealed
    ary << "Stun Guard (Iron Body)" if @iron_body_stun_guard
    ary << "Stun Immunity (Iron Body)" if @iron_body_stun_immunity
    # Need to mark the bonus for feedback field
    ary + super
  end

  def recycle!
    @battery_bonus = @battery_charge
    @battery_charge = nil
    log_me!("gets +4 priority from battery.") if @battery_bonus

    @iron_body_stun_guard = false
    @iron_body_stun_immunity = false
    @bonuses = []
    super
  end

  def bonus_power_for_feedback_field!
    @bonuses << FeedbackFieldBonus.new(@damage_soaked_this_beat * 2)
  end
end
