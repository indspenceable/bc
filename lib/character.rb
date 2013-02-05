class Character
<<<<<<< HEAD
  attr_reader :character_id,  :position, :hand
=======
  attr_reader :player_id, :position, :hand
>>>>>>> b4edd31112055c6fef3efc582f87d8f97feaaac2
  attr_accessor :opponent
  def initialize player_id, input_manager, events
    @player_id = player_id
    @input_manager = input_manager
    @events = events
    @position = player_id == 0 ? 1 : 5
    @clashed_bases = []

    @hand = [
      Grasp.new,
      Drive.new,
      Strike.new,
      Shot.new,
      Burst.new,
      Dash.new
    ]

    @life = 20
  end

  def name
    self.class.character_name
  end

  def reveal_attack_pair!
    "#{@style.name.capitalize} #{@base.name.capitalize}"
  end
  def is_active!
  end
  def is_reactive!
  end

  def bases
    @hand.select do |card|
      card.is_a?(Base)
    end
  end
  def styles
    @hand.select do |card|
      card.is_a?(Style)
    end
  end


  %w(reveal! start_of_beat! before_activating! on_hit! on_damage!
    after_activating! end_of_beat!).each do |trigger|
    define_method(trigger) do
      #TODO - this is wrong. this should be recalculated after each iteration, keeping track of
      #whats been done so far this turn. This way, stuff like zaam's paradigm switches
      # will work correctly.
      actions_to_do = {}
      effect_sources.each do |source|
        if source.respond_to?(trigger)
          actions_to_do.merge!(source.send(trigger))
        end
      end
      while actions_to_do.any?
        if actions_to_do.count > 1
          @input_manager.require_single_input!(player_id, "choose_action_from:#{actions_to_do.keys.join(',')}",
            ->(text) { actions_to_do.key?(text) })

          actions_to_do.delete(@input_manager.answer(player_id)).call(self, @input_manager)
        else
          actions_to_do.values.pop.call(self, @input_manager)
          return
        end
      end
    end
  end

  def priority
    effect_sources.map(&:priority).inject(&:+)
  end
  def power
    effect_sources.map(&:power).inject(&:+)
  end
  def range
    effect_sources.map(&:range).inject(0..0) do |old, obj|
      obj = obj..obj if obj.is_a?(Numeric)
      (old.first + obj.first) .. (old.last + obj.last)
    end
  end

  def stun_guard
    effect_sources.map(&:stun_guard).inject(&:+)
  end
  def soak
    effect_sources.map(&:soak).inject(&:+)
  end

  def take_hit!(damage)
    actual_damage = damage - soak
    stunned! if actual_damage > stun_guard
    @life -= actual_damage
    actual_damage
  end

  def stunned!
    @stunned = true
  end
  def stunned?
    !!@stunned
  end

  def distance
    (position - @opponent.position).abs
  end
  def in_range?
    range.include?(distance)
  end
  def can_ante?
    false
  end
  def recycle!
    @stunned = false
    @hand += @discard2
    @hand += @clashed_bases
    @discard2 = @discard1
    @discard1 = [@style, @base]
    @hand.delete(@base)
    @hand.delete(@style)
  end

  def effect_sources
    sources = []
    sources << @style if @style
    sources << @base if @base
    sources
  end


  def set_attack_pair!(choice)
    choice =~ /([a-z]*)_([a-z]*)/
    @style = styles.find{|s| s.name == $1}
    @base = bases.find{|b| b.name == $2}
  end

  def select_new_base!(choice)
    @clashed_bases << @base
    @hand.delete(@base)
    choice =~ /([a-z]*)/
    @base = bases.find{|b| b.name == $1}
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

  def no_cards?
    @hand.empty?
  end

  # input callbacks. These check the validity of input that the player does.
  # is this the best design? I dunno. It does make it easy for us to identify
  # when theres an error due to invalid input, though.

  # this should probably live in character.
  def valid_discard_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
      s1,b1,s2,b2 = $1, $2, $3, $4
      puts "b1 is #{b1}/#{text}"
      puts "hurr: #{bases.map(&:name).include?(b1)} && #{bases.map(&:name).include?(b2)} && #{b1 != b2} &&
      #{styles.map(&:name).include?(s1)} && #{styles.map(&:name).include?(s2)} && #{s1 != s2}"
      bases.map(&:name).include?(b1) && bases.map(&:name).include?(b2) && b1 != b2 &&
      styles.map(&:name).include?(s1) && styles.map(&:name).include?(s2) && s1 != s2
    end
  end
  def valid_attack_pair_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*)/
      bases.map(&:name).include?($2) && styles.map(&:name).include?($1)
    end
  end
  def base_options_callback
    ->(text) do
      text =~ /([a-z]*)/
      bases.map(&:name).include?($1)
    end
  end
end
