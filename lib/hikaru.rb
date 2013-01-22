require_relative "character"
require_relative "bases"

class Geomantic < Card
  def initialize
    super("geomantic", 0, 1, 0)
  end
  def start_of_beat
    {
      "geomantic_ante_token" => select_from_methods("geomantic_ante_token",
        ante: %w(earth wind fire water pass))
    }
  end
end


class Hikaru < Character
  attr_reader :character_id
  def self.name
    "hikaru"
  end
  def initialize character_id, input_manager, events
    @character_id = character_id
    @input_manager = input_manager
    @events = events

    # set up my hand
    # %w(grasp drive strike shot burst dash palmstrike)
    @bases = [
      #Card.new("grasp",      1, 2, 5),
      Grasp.new,
      Card.new("drive",      1, 3, 4),
      Card.new("strike",     1, 4, 3),
      Card.new("shot",    1..4, 3, 2),
      Burst.new,
      Card.new("dash",     :na,:na,9),
      Card.new("palmstrike", 1, 2, 5),
    ]
    # %(trance focused geomantic sweeping advancing)
    @styles = [
      Card.new("trance", 0..1, 0, 0),
      Card.new("focused",   0, 0, 1),
      Geomantic.new,
      Card.new("sweeping",  0,-1, 3),
      Card.new("advancing", 0, 1, 1),
    ]
    @token_pool = %w(earth wind fire water)
    @token_discard = []
    @current_tokens = []
  end

  def set_initial_discards!(choice)
    choice =~ /([a-z]*)_([a-z]*);([a-z]*)_([a-z]*)/
    s1 = @styles.select{|s| s.name == $1}
    b1 = @bases.select{|b| b.name == $2}
    s2 = @styles.select{|s| s.name == $3}
    b2 = @bases.select{|b| b.name == $4}

    @discard1 = [s1, b1]
    @discard2 = [s2, b2]
    @bases.delete(b1)
    @bases.delete(b2)
    @styles.delete(s1)
    @styles.delete(s2)
  end

  def priority
    effect_sources.map(&:priority).inject(&:+)
  end

  def effect_sources
    sources = []
    sources << @style if @style
    sources << @base if @base
    sources += @current_tokens
    sources
  end

  def set_attack_pair!(choice)
    choice =~ /([a-z]*)_([a-z]*)/
    @style = @styles.select{|s| s.name == $1}.first
    @base = @bases.select{|b| b.name == $2}.first
  end

  def reveal_attack_pair!
  end
  def is_active!
  end
  def is_reactive!
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

  def start_of_beat!
    actions_to_do = {}
    effect_sources.each do |source|
      if source.respond_to?(:start_of_beat)
        actions_to_do.merge!(source.send(:start_of_beat))
      end
    end
    while actions_to_do.any?
      @input_manager.require_single_input!(character_id, "choose_action_from:#{actions_to_do.keys.join(',')}",
        ->(text) { actions_to_do.key?(text) })

      actions_to_do.delete(@input_manager.answer(character_id)).call(self, @input_manager)
    end
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
  def ante_callback
    ->(text) do
      (@token_pool + ["pass"]).include?(text)
    end
  end
end
