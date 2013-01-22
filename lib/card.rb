class Card
  attr_reader :name, :power, :priority, :range
  def initialize name, range, power, priority
    @name = name
    @power = power
    @priority = priority
    @range = range
  end

  # override methods if needed
  %w(reveal start_of_beat, before_activating on_hit on_damage after_activating
    end_of_beat).each do |meth|
    define_method(meth) do
      # blank methods, by default
    end
  end
end
