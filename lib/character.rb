class Character
  def reveal_attack_pair!
  end
  def is_active!
  end
  def is_reactive!
  end
  def stunned?
    !!@stunned
  end


  def start_of_beat!
    #TODO - this is wrong. this should be recalculated after each iteration, keeping track of
    #whats been done so far this turn. This way, stuff like zaam's paradigm switches
    # will work correctly.
    actions_to_do = {}
    effect_sources.each do |source|
      if source.respond_to?(:start_of_beat)
        actions_to_do.merge!(source.send(:start_of_beat))
      end
    end
    while actions_to_do.any?
      if actions_to_do.count > 1
        @input_manager.require_single_input!(character_id, "choose_action_from:#{actions_to_do.keys.join(',')}",
          ->(text) { actions_to_do.key?(text) })

        actions_to_do.delete(@input_manager.answer(character_id)).call(self, @input_manager)
      else
        actions_to_do.values.pop.call(self, @input_manager)
        return
      end
    end
  end

  def can_ante?
    false
  end

  def effect_sources
    sources = []
    sources << @style if @style
    sources << @base if @base
    sources
  end

  # input callbacks. These check the validity of input that the player does.
  # is this the best design? I dunno. It does make it easy for us to identify
  # when theres an error due to invalid input, though.

  # this should probably live in character.
  def valid_discard_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
      s1,b1,s2,b2 = $1, $2, $3, $4
      @bases.map(&:name).include?(b1) && @bases.map(&:name).include?(b2) && b1 != b2 &&
      @styles.map(&:name).include?(s1) && @styles.map(&:name).include?(s2) && s1 != s2
    end
  end
  def valid_attack_pair_callback
    ->(text) do
      text =~ /([a-z]*)_([a-z]*)/
      @bases.map(&:name).include?($2) && @styles.map(&:name).include?($1)
    end
  end
end
