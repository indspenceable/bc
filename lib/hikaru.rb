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

class Sweeping < Style;end
class Trance < Style;end
class Focused < Style;end
class Advancing < Style;end

class Hikaru < Character
  def self.name
    "hikaru"
  end
  def initialize *args
    super

    # set up my hand
    @hand << Card.new("palmstrike", 1, 2, 5)
    @hand += [
      Focused.new("focused",   0, 0, 1),
      Trance.new("trance", 0..1, 0, 0),
      Sweeping.new("sweeping",  0,-1, 3),
      Advancing.new("advancing", 0, 1, 1),
      Geomantic.new,
    ]
    @token_pool = %w(earth wind fire water)
    @token_discard = []
    @current_tokens = []
  end

  def set_initial_discards!(choice)
    choice =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
    s1 = styles.select{|s| s.name == $1}
    b1 = bases.select{|b| b.name == $2}
    s2 = styles.select{|s| s.name == $3}
    b2 = bases.select{|b| b.name == $4}

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

  def set_attack_pair!(choice)
    choice =~ /([a-z]*)_([a-z]*)/
    @style = styles.select{|s| s.name == $1}.first
    @base = bases.select{|b| b.name == $2}.first
  end

  def retreat?(n_s)
    n = Integer(n_s)
    if position < @opponent.position
      n <= position
    else
      n <= 6-position
    end
  end
  def advance?(n_s)
    n = Integer(n_s)
    #like retreat but one space is occupied by opponent.
    if position > @opponent.position
      n <= position-1
    else
      n <= 6-position-1
    end
  end

  def retreat!(n_s)
    n = Integer(n_s)
    if position < @opponent.position
      @position -= n
    else
      @position += n
    end
  end

  def advance!(n_s)
    n = Integer(n_s)
    if position > @opponent.position
      if n >= @position - @opponent.position
        @position -= n+1
      else
        @position -= n
      end
    else
      if n >= @opponent.position - @position
        @position += n+1
      else
        @position += n
      end
    end
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

  def ante_callback
    ->(text) do
      (@token_pool + ["pass"]).include?(text)
    end
  end
end
