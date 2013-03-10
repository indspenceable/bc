class Character
  attr_reader :player_id, :player_name, :position, :hand, :life, :finisher, :damage_dealt_this_beat
  attr_accessor :opponent
  def initialize player_id, player_name, input_manager, events, event_logger
    @player_id = player_id
    @player_name = player_name
    @input_manager = input_manager
    @events = events
    @event_logger = event_logger
    @position = player_id == 0 ? 1 : 5
    @clashed_bases = []
    @token_pool = []
    @token_discard = []

    @hand = [
      Grasp.new,
      Drive.new,
      Strike.new,
      Shot.new,
      Burst.new,
      Dash.new
    ]

    @life = 20
    @special_action_available = true

    #TODO make this work with press.
    @damage_taken_this_beat = 0
    @damage_dealt_this_beat = 0
    @damage_soaked_this_beat = 0
  end

  def name
    self.class.character_name
  end

  def reveal_attack_pair_string
    if @played_finisher
      "#{@finisher.name.capitalize}"
    else
      "#{@style.name.capitalize} #{@base.name.capitalize}"
    end
  end

  def is_active!
  end

  def is_reactive!
  end

  def flag? n
    effect_sources.any?{|s| s.flag? n}
  end

  def discard1(seen_by)
    p = (seen_by == @player_id &&@temp_discard1) || @discard1 || []
    p.map(&:name)
  end
  def discard2(seen_by)
    p = (seen_by == @player_id &&@temp_discard2) || @discard2 || []
    p.map(&:name)
  end

  def bases(seen_by=@player_id)
    # if we haven't revealed, but this not another player
    c_hand = (seen_by == @player_id) ? @hand - [@base, @style] : @hand
    c_hand -= @temp_discard2 if @temp_discard2 && seen_by == @player_id
    c_hand -= @temp_discard1 if @temp_discard1 && seen_by == @player_id
    c_hand.select do |card|
      card.is_a?(Base)
    end
  end
  def styles(seen_by=@player_id)
    c_hand = (seen_by == @player_id) ? @hand - [@base, @style] : @hand
    c_hand -= @temp_discard2 if @temp_discard2 && seen_by == @player_id
    c_hand -= @temp_discard1 if @temp_discard1 && seen_by == @player_id
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
  def special_action_name(seen_by=@player_id)
    (seen_by == @player_id || @revealed) && @played_finisher && finisher.name
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
    @hand.delete(@base) if @base
    @hand.delete(@style) if @style
    @revealed = true
    if @played_finisher
      log_me!("reveals #{@finisher.name}")
    else
      log_me!("reveals #{@style.name} #{@base.name}")
    end

    effect_sources.each do |source|
      if source.respond_to?(:reveal!)
        source.reveal!(self)
      end
    end
  end

  def passive_abilities!
    effect_sources.each do |source|
      if source.respond_to?(:passive!)
        source.passive!(self)
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
    effect_sources.any?(&:stun_immunity?)
  end

  def take_hit!(damage)
    effective_soak = (opponent.ignore_soak?? 0 : soak)
    effective_soak = damage if effective_soak > damage
    actual_damage = damage - effective_soak
    @damage_soaked_this_beat += effective_soak

    receive_damage!(actual_damage)
    stunned! if exceeds_stun_guard?(actual_damage)
    actual_damage
  end

  def log_me!(msg)
    @event_logger.call("#{player_name} #{msg}")
  end

  def receive_damage!(damage)
    log_me!("gets hit for #{damage} damage")
    @damage_taken_this_beat += damage
    @life -= damage
    throw :ko unless alive?
  end
  def alive?
    @life > 0
  end

  def lose_life!(amount)
    log_me!("loses #{amount} life")
    @life -= Integer(amount)
  end

  def gain_life!(amount)
    log_me!("gains #{amount} life")
    @life += amount
  end

  def exceeds_stun_guard?(amt)
    amt > stun_guard || (amt > 0 && opponent.ignore_stun_guard?)
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
    # Don't cycle cards on turns we play finishers.
    unless @played_finisher
      @hand += @discard2
      @discard2 = @discard1
      @discard1 = [@style, @base]
    end
    @damage_taken_this_beat = 0
    @damage_dealt_this_beat = 0
    @damage_soaked_this_beat = 0
    @dodge = false
    @base = @style = nil
    @played_finisher = false
  end

  def effect_sources
    sources = []
    sources << @style if @style
    sources << @base if @base
    sources << @finisher if @played_finisher
    sources += @opponent.opponent_effect_sources
    sources
  end
  # effect sources provided by your opponent, like trap penalty
  def opponent_effect_sources
    []
  end
  def set_initial_discard2(choice)
    choice =~ /([a-z]*)_([a-z]*)/
    s1 = styles.find{|s| s.name == $1}
    b1 = bases.find{|b| b.name == $2}
    @temp_discard2 = [s1, b1]
  end
  def set_initial_discard1(choice)
    choice =~ /([a-z]*)_([a-z]*)/
    s1 = styles.find{|s| s.name == $1}
    b1 = bases.find{|b| b.name == $2}
    @temp_discard1 = [s1, b1]
  end
  def set_initial_discards!
    @discard2 = @temp_discard2
    @discard1 = @temp_discard1
    (@temp_discard1 + @temp_discard2).each do |c|
      @hand.delete(c)
    end
    @temp_discard1 = nil
    @temp_discard2 = nil
    log_me!("discards #{@discard2.map(&:name).join(' ')} to discard 2.")
    log_me!("discards #{@discard1.map(&:name).join(' ')} to discard 1.")
    log_me!("selects #{@finisher.name} for their finisher.")
  end

  def select_finisher!(n)
    @finisher = finishers.find{|f| f.name == n}
  end

  def set_attack_pair!(choice)
    @revealed = false
    choice =~ /([a-z]*)_([a-z]*)/
    @style = styles.find{|s| s.name == $1}
    @base = bases.find{|b| b.name == $2}
  end

  def retreat?(n_s)
    n = Integer(n_s)
    if position < @opponent.position
      traversed_spaces = position.downto(position - n_s).to_a
    else
      traversed_spaces = position.upto(position + n_s).to_a
    end
    return false if traversed_spaces.any?{|x| x < 0 || x > 6 }
    return false if (@opponent.blocked_spaces & traversed_spaces).any?
    true
  end

  def advance?(n_s)
    n = Integer(n_s)
    jump = n_s < distance ? 0 : 1
    if position > @opponent.position
      traversed_spaces = position.downto(position - n_s - jump).to_a
    else
      traversed_spaces = position.upto(position + n_s + jump).to_a
    end
    return false if traversed_spaces.any?{|x| x < 0 || x > 6 }
    return false if (@opponent.blocked_spaces & traversed_spaces).any?
    true
  end

  def blocked_spaces
    []
  end

  def teleport_to?(n)
    opponent.position != Integer(n)
  end
  def teleport_to!(n)
    @position = Integer(n)
  end
  def teleport_to_unoccupied_space!
    select_from_methods(teleport_to: [0,1,2,3,4,5,6]).call(self, @input_manager)
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
    @event_logger.call("#{player_name} advances #{n_s} to space #{@position}") if log_event
  end

  def retreat!(n_s,log_event=true)
    n = Integer(n_s)
    if position < @opponent.position
      @position -= n
    else
      @position += n
    end
    #TODO - this looks like a bug.
    @event_logger.call("#{player_name} retreats #{n_s} to space #{@position + 1}") if log_event
  end

  def pull?(n)
    @opponent.advance?(n)
  end

  def push?(n)
    @opponent.retreat?(n)
  end

  def push!(n)
    @opponent.retreat!(n, false)
    @event_logger.call("#{opponent.player_name} gets pushed #{n} to space #{@opponent.position}")
  end
  def pull!(n)
    opponent.advance!(n, false)
    @event_logger.call("#{opponent.player_name} gets pulled #{n} to space #{@opponent.position}")
  end


  def no_bases?
    bases.empty?
  end

  def ante_options
    opts = ["pass"]
    opts << "finisher" if can_play_finisher?
    opts
  end

  def token_pool
    []
  end

  # This must be overwritten if your character does not use a @token_discard
  def discard_token!(choice)
    @token_discard += @token_pool.reject{ |token| token.name != choice }
    @token_pool.delete_if{ |token| token.name == choice }
  end

  def discard_token?
    @token_pool.any?{|token| token.name == choice}
  end

  def current_effects
    @opponent.current_opponent_effects
  end
  # these are current effects provided by your opponent, like trap penalty
  def current_opponent_effects
    []
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

  def can_play_finisher?
    life <= 7 && @special_action_available
  end

  def ante?(choice)
    return true if choice == "pass"
    return true if choice == "finisher" && can_play_finisher?
    false
  end
  def ante!(choice)
    if choice == "finisher"
      log_me!("antes their finisher: #{@finisher.name}.")
      @style = nil
      @base = nil
      @played_finisher = true
      @special_action_available = false
      true
    end
  end

  def played_finisher?
    @played_finisher
  end

  def cancel_finisher!
    @played_finisher = false
  end

  def ignore_soak?
    effect_sources.any?{|source| source.ignore_soak? }
  end

  def ignore_stun_guard?
    effect_sources.any?{|source| source.ignore_stun_guard? }
  end

  def execute_attack!
    before_activating!
    # are they in range?
    if in_range?
      on_hit!
      damage_dealt = opponent.take_hit!(power)
      log_me!("hits #{opponent.player_name} for #{damage_dealt} damage!")
      on_damage! if damage_dealt > 0
    else
      log_me!("misses!")
    end
    after_activating!
  end

  # input callbacks. These check the validity of input that the player does.
  # is this the best design? I dunno. It does make it easy for us to identify
  # when theres an error due to invalid input, though.

  def valid_attack_pair_callback(previous_answer=nil)
    ->(text) do
      text =~ /([a-z]*)_([a-z]*)/
      base_name = $2
      style_name = $1
      if previous_answer
        previous_answer =~ /([a-z]*)_([a-z]*)/
        return false if $2 == base_name || $1 == style_name
      end
      bases.map(&:name).include?(base_name) && styles.map(&:name).include?(style_name)
    end
  end
  def base_options_callback
    ->(text) do
      text =~ /([a-z]*)/
      bases.map(&:name).include?($1)
    end
  end
end
