class EventManager
  def initialize(number_of_events=nil)
    @number_of_events = number_of_events
    @event_log = []
  end

  def log! message
    @event_log << message
    throw :halt if @number_of_events == @event_log.size
  end

  def to_a
    @event_log
  end
end
