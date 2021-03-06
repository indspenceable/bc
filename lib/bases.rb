require 'card'

class Grasp < Base
  def initialize
    super("grasp", 1, 2, 5)
  end
  def on_hit!
    {
      "move_opponent" => select_from_methods("(Grasp) Move opponent 1 space.", pull: [1], push: [1])
    }
  end
end

class Drive < Base
  def initialize
    super("drive", 1, 3, 4)
  end
  def before_activating!
    {
      'advance' => select_from_methods("(Drive) Advance 1 or 2 spaces.", advance: [1, 2])
    }
  end
end

class Strike < Base
  def initialize
    super("strike", 1, 4, 3)
  end
  def stun_guard
    5
  end
end

class Shot < Base
  def initialize
    super("shot", 1..4, 3, 2)
  end
  def stun_guard
    2
  end
end

class Burst < Base
  def initialize
    super("burst", 2..3, 3, 1)
  end
  def start_of_beat!
    {
      "retreat" => select_from_methods("(Burst) Retreat 1 or 2 spaces", retreat: [1, 2])
    }
  end
end
class Dash < Base
  def initialize
    super('dash', nil, 0, 9)
  end
  def after_activating!
    {
      "move" => ->(me, inpt) {
        direction = me.position - me.opponent.position
        select_from_methods("(Dash) Move 1, 2, or 3 spaces.",
          retreat: [1, 2, 3], advance: [1, 2, 3]).call(me, inpt)
        if (me.position - me.opponent.position) * direction < 0
          me.dash_dodge!
        end
      }
    }
  end
end

class SpecialAction < Style
  def initialize
    super('specialaction', 0, 0, 0)
  end
  def effect
    ""
  end
end
