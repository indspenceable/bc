require_relative "card"

class Grasp < Card
  def initialize
    super("grasp", 1, 2, 5)
  end
  def on_hit()
    {
      "grasp_move_opponent" => select_from_methods("grasp_move_opponent",
        pull: [1], push: [1])
    }
  end
end

class Drive < Card
  def initialize
    super("drive", 1, 3, 4)
  end
  def before_activation
    {'drive_advance' => select_from_methods(
      advance: [1,2])
    }
  end
end

class Strike < Card
  def initialize
    super("strike", 1, 4, 3)
  end
end

class Shot < Card
  def initialize
    super("shot", 1..4, 3, 2)
  end
end

class Burst < Card
  def initialize
    super("burst", 2..3, 3, 1)
  end
  def start_of_beat()
    {
      "burst_move_back" => select_from_methods("burst_move_back",
        retreat: [1, 2])
    }
  end
end
