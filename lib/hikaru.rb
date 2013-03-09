require "character"
require "bases"

class Geomantic < Style
  def initialize
    super("geomantic", 0, 1, 0)
  end
  def start_of_beat!
    {
      "geomantic_ante_token" => select_from_methods(
        # the question should be helpful to the UI
        # in this case, we'll probably have a case in the UI for ante
        # but we don't yet :)
        ante: %w(earth wind fire water pass))
    }
  end
end
class Focused < Style
  def initialize
    super("focused", 0, 1, 0)
  end
  def stun_guard
    2
  end
  def on_hit!
    {
      "focused_recover_token" => ->(me, inputs) {me.recover_token!}
    }
  end
end

class Trance < Style
  def initialize
    super('trance', 0..1, 0, 0)
  end

  flag :no_token_bonus

  def reveal!(me)
    me.return_tokens_to_pool!
  end
  def end_of_beat!
    {
      "trance_recover_token" => ->(me, inputs) {me.recover_token!}
    }
  end
end

class Sweeping < Style
  def initialize
    super('sweeping', 0, -1, 3)
  end
  # TODO - sweeping extra hit
  flag :sweeping_extra_damage
end

class Advancing < Style
  def initialize
    super('advancing', 0, 1, 1)
  end
  def start_of_beat!
    #TODO - this doesn't check that you passed your opponent...
    {
      'advancing_advance' => ->(me, inpt) {
        direction = me.position - me.opponent.position
        select_from_methods(advance: [1]).call(me,inpt)
        if (me.position - me.opponent.position)*(direction) < 0
          me.advancing_bonus!
        end
      }
    }
  end
end
class PalmStrike < Base
  def initialize
    super('palmstrike', 1, 2, 5)
  end
  def start_of_beat!
    #TODO - this doesn't check that you passed your opponent...
    {
      'palmstrike_advance' => select_from_methods(advance: [1])
    }
  end
  def on_damage!
    {
      "palmstrike_recover_token" => ->(me, inputs) {me.recover_token!}
    }
  end
end

class Fire < Token
  def initialize
    super("fire", 0, 3, 0)
  end
  def name_and_effect
    "#{name.capitalize} (+3 power)"
  end
end

class Earth < Token
  def initialize
    super("earth", 0, 0, 0)
  end
  def soak
    3
  end
  def name_and_effect
    "#{name.capitalize} (soak 3)"
  end
end

class Wind < Token
  def initialize
    super("wind", 0, 0, 2)
  end
  def name_and_effect
    "#{name.capitalize} (+2 priority)"
  end
end

class Water < Token
  def initialize
    super("water", -1..1, 0, 0)
  end
  def name_and_effect
    "#{name.capitalize} (-1 ~ +1 range)"
  end
end

class WrathOfElements < Finisher
  def initialize
    super("wrathofelements", 1, 7, 6)
  end
  def reveal!(me)
    ['earth', 'fire', 'wind', 'water'].each do |token|
      me.ante!(token) if me.ante?(token)
    end
  end
end

class FourWinds < Finisher
  def initialize
    super("fourwinds", 1, 2, 5)
  end

  flag :no_token_bonus

  def before_activating!
    {
      "advance" => select_from_methods(advance: [0,1])
    }
  end
  def on_hit!
    {
      "repeat" => ->(me, inputs) { me.regain_token_and_repeat! }
    }
  end
end

class Hikaru < Character
  def self.character_name
    "hikaru"
  end
  def initialize *args
    super

    # set up my hand
    @hand << PalmStrike.new
    @hand += [
      Focused.new,
      Trance.new,
      Sweeping.new,
      Advancing.new,
      Geomantic.new,
    ]
    # tokens available
    @token_pool = [
      Earth.new,
      Wind.new,
      Fire.new,
      Water.new
    ]
    # tokens not available
    @token_discard = []
    # tokens used this beat
    @current_tokens = []
  end

  def finishers
    [WrathOfElements.new, WrathOfElements.new]
  end

  def effect_sources
    sources = super
    sources += @current_tokens unless sources.any?{|s| s.flag? :no_token_bonus }
    sources
  end

  def reveal!
    @advancing_bonus = false
    super
  end

  # can we generalize this pattern?
  def advancing_bonus!
    @advancing_bonus = true
  end

  def take_hit!(damage)
    if flag?(:sweeping_extra_damage)
      super(damage+2)
    else
      super(damage)
    end
  end

  def power
    if @advancing_bonus
      super+1
    else
      super
    end
  end

  def current_effects
    super + @current_tokens.map(&:name_and_effect)
  end

  def recycle!
    super
    @token_discard += @current_tokens
    @current_tokens = []
  end

  def can_ante?
    @token_pool.any?
  end

  def ante_options
    (@current_tokens.empty? ? @token_pool.map(&:name) : []) + super
  end
  def token_pool
    @token_pool.map(&:name_and_effect)
  end

  def ante!(choice)
    if choice == "pass"
      log_me!("passes.")
      return
    end
    log_me!("antes #{@token_pool.find{ |token| token.name == choice }.name_and_effect}")
    @current_tokens += @token_pool.reject{ |token| token.name != choice }
    @token_pool.delete_if{ |token| token.name == choice }
  end

  def ante?(choice)
    return true if choice == "pass"
    @token_pool.any?{ |token| (token.name == choice) }
  end

  def recover_token!
    select_from_methods(recover: %w(earth fire water wind)).call(self, @input_manager)
  end

  # Checks if hikaru can recover the given token
  def recover?(choice)
    # return true if choice == "pass"
    @token_discard.any?{|token| token.name == choice}
  end

  def recover!(choice)
    log_me!("recovers #{choice}")
    # return if token == "pass"
    @token_pool += @token_discard.reject{ |token| token.name != choice }
    @token_discard.delete_if{ |discarded_token| discarded_token.name == choice }
  end

  def regain_token_and_repeat!
    if @token_pool.any?
      @token_pool << @token_discard.pop
      execute_attack!
    end
  end

  def return_tokens_to_pool!
    @token_pool += @current_tokens
    @current_tokens = []
  end
end
