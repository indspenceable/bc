require "character"
require "bases"

class ZaamassalStyle < Style
  def initialize *args, paradigm
    @paradigm = paradigm
    super(*args)
  end
  def after_activating!
    {
      "assume_#{@paradigm}" => select_from_methods(assume_paradigm: ['pass', @paradigm])
    }
  end
end

class Malicious < ZaamassalStyle
  def initialize
    super("malicious", 0, 1, -1, 'pain')
  end
  def stun_guard
    2
  end
end

class Warped < ZaamassalStyle
  def initialize
    super('warped', 0..2, 0, 0, 'distortion')
  end
  def start_of_beat!
    {
      "retreat" => select_from_methods(retreat: [1])
    }
  end
end

class Sturdy < ZaamassalStyle
  def initialize
    super('sturdy', 0, 0, 0, 'resilience')
  end
  def stun_immunity?
    true
  end

  # Todo - make this work.
  flag :ignore_movement
end

class Urgent < ZaamassalStyle
  def initialize
    super("urgent", 0..1, -1, 2, 'haste')
  end
  def before_activating!
    {
      "advance" => select_from_methods(advance: [0, 1])
    }
  end
end

class Sinuous < ZaamassalStyle
  def initialize
    super("sinuous", 0, 0, 1, 'fluidity')
  end
  def end_of_beat!
    {
      "teleport" => ->(me, input) { me.teleport_to_unoccupied_space! }
    }
  end
end

class ParadigmShift < Base
  def initialize
    super("paradigmshift", 2..3, 3, 3)
  end
  def before_activating!
    {
      "select_paradigm" => select_from_methods(assume_paradigm: %w(pain distortion resilience haste fluidity))
    }
  end
end

class Paradigm < Card;end

class Pain < Paradigm
  def initialize
    super("pain", 0, 0, 0)
  end

  def on_damage!
    {
      "life_loss" => ->(me, input) { me.opponent.lose_life!(2) }
    }
  end
end

class Distortion < Paradigm
  def initialize
    super("distortion", 0, 0, 0)
  end
  flag :distortion
end

class Fluidity < Paradigm
  def initialize
    super("fluidity", 0, 0, 0)
  end
  def before_activating!
    {
      "movement" => select_from_methods(advance: [0,1])
    }
  end
  def end_of_beat!
    {
      "movement" => select_from_methods(advance: [0,1])
    }
  end
end

class Resilience < Paradigm
  def initialize
    super("resilience", 0, 0, 0)
  end
  def start_of_beat!
    {
      "gain_soak" => ->(me, input) { me.gain_soak! }
    }
  end
  def after_activating!
    {
      "lose_soak" => ->(me, input) { me.lose_soak! }
    }
  end
end

class Haste < Paradigm
  def initialize
    super("haste", 0, 0, 0)
  end
  flag :wins_ties
  flag :stop_movement_if_adjacent
end

class ResilienceSoak < Card
  def initialize
    super("soakfromresilience", 0, 0, 0)
  end
  def soak
    2
  end
  def name_and_effect
    "Resilience (Soak 2)"
  end
end

class OpenTheGate < Finisher
  def initialize
    super("openthegate", 1..2, 3, 7)
  end
  def on_hit!
    {
      "stun_and_paradigm" => ->(me, inputs) {
        me.opponent.stunned!
        me.assume_three_paradigms!
      }
    }
  end
end

class PlanarDivider < Finisher
  def initialize
    super("planardivider", 1, 2, 5)
  end
  def before_activating!
    {
      "move_anywhere" => ->(me, inputs) { me.teleport_to_unoccupied_space! }
    }
  end
  def on_hit!
    {
      "move_opponent" => ->(me, inputs) {
        select_from_methods(teleport_opponent_to: [0,1,2,3,4,5,6]).call(me,inputs)
        me.gain_power_for_distance!
        select_from_methods(assume_paradigm: %w(pain distortion resilience haste fluidity)).call(me, inputs)
      }
    }
  end
end

class PlanarDividerPowerBonus < Token
  def initialize p
    super("planardividerpowerbonus", 0, p, 0)
  end
  def name_and_effect
    "Planar Divider power bonus"
  end
end

class Zaamassal < Character
  def self.character_name
    "zaamassal"
  end
  def initialize *args
    super

    # set up my hand
    @hand << ParadigmShift.new
    @hand += [
      Malicious.new,
      Warped.new,
      Sturdy.new,
      Urgent.new,
      Sinuous.new
    ]
    @paradigms = []
    @bonuses = []
  end

  def finishers
    [OpenTheGate.new, PlanarDivider.new]
  end

  def effect_sources
    sources = super
    sources += @bonuses
    sources += @paradigms
    sources
  end

  def current_effects
    effects = []
    effects += @paradigms.map{|p| "Paradigm of #{p.name}"} if @paradigms.any?
    effects += super
    effects += @bonuses.map(&:name_and_effect)
    effects
  end

  def token_pool
    pool = []
    # pool += @paradigms.map(&:name) if @paradigms.any?
    pool
  end

  def in_range?
    return true if super
    return (distance == 3 || distance == 4) if flag? :distortion
  end

  def dodges?
    return true if super
    return (distance == 3 || distance == 4) if flag? :distortion
  end

  def gain_soak!
    @soak = ResilienceSoak.new
    @bonuses << @soak
  end
  def lose_soak!
    @bonuses.delete(@soak)
  end

  def recycle!
    @bonuses = []
    super
  end

  def blocked_spaces
    return (0..6).to_a if flag?(:stop_movement_if_adjacent) && (distance == 1)
    []
  end

  def stunned!
    super
    log_me!("loses his paradigms.")
    @paradigms = [] if @stunned
  end

  def assume_three_paradigms!
    @paradigms = []
    3.times do
      select_from_methods(assume_paradigm_multi: %w(pain distortion resilience haste fluidity)).call(self, @input_manager)
    end
  end

  def paradigm_name_to_instance(n)
    paradigm_map = {
      'pain' => Pain.new,
      'distortion' => Pain.new,
      'resilience' => Resilience.new,
      'haste' => Haste.new,
      'fluidity' => Fluidity.new,
    }[n]
  end

  def gain_power_for_distance!
    @bonuses << PlanarDividerPowerBonus.new(distance)
  end

  def assume_paradigm?(choice)
    return true
  end
  def assume_paradigm!(choice)
    return if choice == 'pass'
    @paradigms = [paradigm_name_to_instance(choice)]
  end

  def assume_paradigm_multi?(choice)
    !@paradigms.any?{|p| p.name == choice }
  end
  def assume_paradigm_multi!(choice)
    @paradigms << paradigm_name_to_instance(choice)
  end
end
