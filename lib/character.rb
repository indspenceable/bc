class Character
  attr_reader :player_id, :position, :hand, :life
  attr_accessor :opponent
  def initialize player_id, input_manager, events, event_logger
    @player_id = player_id
    @input_manager = input_manager
    @events = events
    @event_logger = event_logger
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

  def bases(seen_by=@player_id)
    # if we haven't revealed, but this not another player
    c_hand = (seen_by == @player_id) ? @hand - [@base, @style] : @hand
    c_hand.select do |card|
      card.is_a?(Base)
    end
  end
  def styles(seen_by=@player_id)
    c_hand = (seen_by == @player_id) ? @hand - [@base, @style] : @hand
    c_hand.select do |card|
      card.is_a?(Style)
    end
  end
  def current_base_name(seen_by=@player_id)
    # either its the current player, or we've revealed, and theres a base, then
    # return its name
    (seen_by == @player_id || @revealed) && @base && @base.name

  end
  def current_style_name(seen_by=@player_id)
    # either its the current player, or we've revealed, and theres a style, then
    # return its name
    (seen_by == @player_id || @revealed) && @style && @style.name
  end
  def clash!
    @clashed_bases << @base
    @base = nil
  end

  def select_new_base!(choice)
    choice =~ /([a-z]*)/
    @base = bases.find{|b| b.name == $1}
    @hand.delete(@base)
  end
  def regain_bases!
    @hand += @clashed_bases
    @clashed_bases = []
  end
  def regain_cards!
    regain_bases!
    @hand << @style
    @style = nil
  end

  # order doens't matter on reveal.
  def reveal!
    @hand.delete(@base)
    @hand.delete(@style)
    @revealed = true

    effect_sources.each do |source|
      if source.respond_to?(:reveal!)
        source.reveal!(self)
      end
    end
  end

  def passive_abilities!
    effect_sources.each do |source|
      if source.respond_to?(:passive!)
        source.reveal!(self)
      end
    end
  end

  %w(start_of_beat! before_activating! on_hit! on_damage!
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
          @input_manager.require_single_input!(player_id, "select_from:#{actions_to_do.keys.map{|x| "<#{x}>"}}",
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
      break nil if old.nil? || obj.nil?
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

  def stun_immunity?
    effect_sources.any?(&:stun_immunity)
  end

  def take_hit!(damage)
    actual_damage = damage - soak
    actual_damage = 0 if actual_damage < 0
    receive_damage!(actual_damage)
    stunned! if exceeds_stun_guard?(actual_damage)
    actual_damage
  end

  def log_me!(msg)
    @event_logger.call("P#{player_id} #{msg}")
  end

  def receive_damage!(damage)
    log_me!("gets hit for #{damage} damage")
    @life -= damage
  end

  def exceeds_stun_guard?(amt)
    amt > stun_guard
  end

  def stunned!
    # can't get stunned with stun immunity!
    unless stun_immunity?
      log_me!("is stunned!")
      @stunned = true
    end
  end
  def stunned?
    !!@stunned
  end

  def distance
    (position - @opponent.position).abs
  end
  def in_range?
    range && range.include?(distance) && !opponent.dodges?
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
    @base = @style = nil
  end

  def effect_sources
    sources = []
    sources << @style if @style
    sources << @base if @base
    sources
  end

  def set_initial_discards!(choice)
    choice =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
    s1 = styles.find{|s| s.name == $1}
    b1 = bases.find{|b| b.name == $2}
    s2 = styles.find{|s| s.name == $3}
    b2 = bases.find{|b| b.name == $4}

    @discard2 = [s1, b1]
    @discard1 = [s2, b2]
    @hand.delete(b1)
    @hand.delete(b2)
    @hand.delete(s1)
    @hand.delete(s2)
  end

  def set_attack_pair!(choice)
    @revealed = false
    choice =~ /([a-z]*)_([a-z]*)/
    @style = styles.find{|s| s.name == $1}
    @base = bases.find{|b| b.name == $2}
  end

  def retreat?(n_s, push=false)
    n = Integer(n_s)
    if position < @opponent.position
      traversed_spaces = position.downto(position - n_s).to_a
    else
      traversed_spaces = position.upto(position + n_s).to_a
    end
    return false if traversed_spaces.any?{|x| x < 0 || x > 6 }
    return false if !push && (@opponent.blocked_spaces & traversed_spaces).any?
    true
  end

  def advance?(n_s, pull=false)
    n = Integer(n_s)
    jump = n_s < distance ? 0 : 1
    if position > @opponent.position
      traversed_spaces = position.downto(position - n_s - jump).to_a
    else
      traversed_spaces = position.upto(position + n_s + jump).to_a
    end
    return false if traversed_spaces.any?{|x| x < 0 || x > 6 }
    return false if !pull && (@opponent.blocked_spaces & traversed_spaces).any?
    true
  end

  def blocked_spaces
    []
  end

  def advance!(n_s,log_event=true)
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
    @event_logger.call("Player #{player_id} advances #{n_s} to space #{@position}") if log_event
  end

  def retreat!(n_s,log_event=true)
    n = Integer(n_s)
    if position < @opponent.position
      @position -= n
    else
      @position += n
    end
    @event_logger.call("Player #{player_id} retreats #{n_s} to space #{@position + 1}") if log_event
  end

  def pull?(n)
    @opponent.advance?(n, true)
  end

  def push?(n)
    @opponent.retreat?(n, true)
  end

  def push!(n)
    @opponent.retreat!(n, false)
    @event_logger.call("Player #{@opponent.player_id} gets pushed #{n} to space #{@opponent.position}")
  end
  def pull!(n)
    opponent.advance!(n, false)
    @event_logger.call("Player #{@opponent.player_id} gets pulled #{n} to space #{@opponent.position}")
  end


  def no_bases?
    bases.empty?
  end

  def ante_options
    ["pass"]
  end

  def token_pool
    []
  end

  def current_effects
    []
  end

  def clear_old_effects!
    @dodge = false
  end
  def dash_dodge!
    @dodge = true
  end
  def dodges?
    @dodge
  end

  def extra_data
    {}
  end

  def ante?(choice)
    return true if choice == "pass"
    false
  end
  def ante!(choice)
  end

  # input callbacks. These check the validity of input that the player does.
  # is this the best design? I dunno. It does make it easy for us to identify
  # when theres an error due to invalid input, though.

  # this should probably live in character.
  def valid_discard_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
      s1,b1,s2,b2 = $1, $2, $3, $4
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
