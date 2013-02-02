require_relative "card" 

class Grasp < Base
  def initialize
    super("grasp", 1, 2, 5)
  end
  def on_hit!
    {
      "grasp_move_opponent" => select_from_methods("grasp_move_opponent",
        pull: [1], push: [1])
    }
  end
end

class Drive < Base
  def initialize
    super("drive", 1, 3, 4)
  end
  def before_activating!
    {'drive_advance' => select_from_methods("drive_advance",
      advance: [1,2])
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
      "burst_move_back" => select_from_methods("burst_move_back",
        retreat: [1, 2])
    }
  end
end
class Dash < Base
  def initialize
    super('dash', 0, 0, 9)
  end
  def after_activating!
    {
      "dash_move" => select_from_methods("dash_move",
        retreat: [1, 2, 3], advance: [1, 2, 3])
    }
  end
end
