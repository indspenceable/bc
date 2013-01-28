require_relative "character"
require_relative "bases"

class Geomantic < Style
  def initialize
    super("geomantic", 0, 1, 0)
  end
  def start_of_beat!
    {
      "geomantic_ante_token" => select_from_methods("geomantic_ante_select",
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
end

class Advancing < Style
  def initialize
    super('advancing', 0, 1, 1)
  end
  def start_of_beat!
    #TODO - this doesn't check that you passed your opponent...
    {
      'advancing_advance' => select_from_methods('advance', advance: [1])
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
      'palmstrike_advance' => select_from_methods('advance', advance: [1])
    }
  end
  def on_damage!
    {
      "palmstrike_recover_token" => ->(me, inputs) {me.recover_token!}
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
    @token_pool = %w(earth wind fire water)
    @token_discard = []
    @current_tokens = []
  end

  def set_initial_discards!(choice)
    choice =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
    s1 = styles.find{|s| s.name == $1}
    b1 = bases.find{|b| b.name == $2}
    s2 = styles.find{|s| s.name == $3}
    b2 = bases.find{|b| b.name == $4}

    @discard1 = [s1, b1]
    @discard2 = [s2, b2]
    @hand.delete(b1)
    @hand.delete(b2)
    @hand.delete(s1)
    @hand.delete(s2)
  end

  def effect_sources
    super + @current_tokens
  end


  def recycle!
    super
    @token_discard += @current_tokens
    @current_tokens = []
  end

  def can_ante?
    @token_pool.any?
  end

  def ante!(choice)
    return if choice == "pass"
    @current_tokens << @token_pool.delete(choice)
  end

  def ante?(choice)
    (@token_pool + ["pass"]).include?(choice)
  end

  def recover_token!
    select_from('recover_token', recover: %w(earth fire water wind)).call(me,@input_manager)
  end
  def recover?(token)
    @token_discard.include?(token)
  end
  def recover!(token)
    @token_pool << @token_discard.delete(token)
  end

  def ante_callback
    ->(text) do
      (@token_pool + ["pass"]).include?(text)
    end
  end
end
