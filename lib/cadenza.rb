require_relative "character"
require_relative "bases"

class Battery < Style
  def initialize
    super("battery", 0, 1, -1)
  end
  def end_of_beat!
    {
      "battery_charge" => ->(me, inpt) {
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
      "hydraulic_advance" => select_from_methods(advance: [1])
    }
  end
end

class Mechanical < Style
  def initialize
    super("mechanical", 0, 2, -2)
  end

  def end_of_beat!
    {
      "mechanical_advance" => select_from_methods(advance: [0,1,2,3])
    }
  end
end
class Grapnel < Style
  def initialize
    super("grapnel", 2..4, 0, 0)
  end

  def on_hit!
    {
      "grapnel_pull" => select_from_methods(pull: [0,1,2,3])
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
  def reveal!(me)
    me.reveal_press!
  end
end

class IronBodyStunImmunity < Token
  def stun_immunity
    true
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
  end
  def self.character_name
    'cadenza'
  end
  def charge_battery!
    @battery_charge = true
  end
  def reveal_press!
    @press_charge_up = true
  end

  def receive_damage!(damage)
    super
    if damage > 0 && @token_count > 0 && exceeds_stun_guard?(damage)
      select_from_methods(iron_body: ['yes', 'pass']).call(self, @input_manager)
    end
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
    if @press_charge_up
      log_me!("gets #{@press_charge_ammount} bonus damage from press!")
      @press_charge_ammount + super
    else
      super
    end
  end
  def priority
    (@battery_bonus ? 4 : 0) + super
  end
  def token_pool
    (["Iron Body"] * @token_count) + super
  end

  #ante-ing iron body tokens
  def ante_options
    (@iron_body_stun_immunity ? [] : ["ironbody"]) + super
  end

  def ante?(action)
    return true if action == "pass"
    return @token_count > 0
  end
  def ante!(action)
    return if action == "pass"
    @token_count -= 1
    @iron_body_stun_immunity = true
  end

  def current_effects
    ary = []
    ary << "Battery (+4 Priority)" if @battery_bonus
    ary << "Press (+#{@press_charge_ammount} damage)" if @press_charge_up
    ary << "Stun Guard (Iron Body)" if @iron_body_stun_guard
    ary << "Stun Immunity (Iron Body)" if @iron_body_stun_immunity
    ary + super
  end

  def recycle!
    @battery_bonus = @battery_charge
    @battery_charge = nil
    log_me!("gets +4 priority from battery.") if @battery_bonus

    @press_charge_up = nil
    @press_charge_ammount = 0

    @iron_body_stun_guard = false
    @iron_body_stun_immunity = false
    super
  end
end
