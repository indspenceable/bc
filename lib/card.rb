class Card
  attr_reader :name, :power, :priority, :range
  def initialize name, range, power, priority
    @name = name
    @power = power
    @priority = priority
    @range = range
  end

  def self.flag name
    @flags ||= []
    @flags << name
  end
  def self.flag? name
    @flags ||= []
    @flags.include? name
  end
  def flag? name
    self.class.flag? name
  end

  # override methods if needed
  %w(reveal start_of_beat, before_activating on_hit on_damage after_activating
    end_of_beat).each do |meth|
    define_method(meth) do
      # blank methods, by default
    end
  end

  def stun_guard
    0
  end
  def soak
    0
  end
  def stun_immunity?
    false
  end
  def ignore_soak?
    false
  end
  def ignore_stun_guard?
    false
  end
end

class Style < Card;end
class Base < Card;end
class Token < Card;end
