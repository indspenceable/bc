class EventManager
  def initialize(number_of_events=nil)
    @number_of_events = number_of_events
    @event_log = []
    @major_events = 0
  end

  def log! message, major_event=true
    @event_log << message
    if major_event
      @major_events += 1
      throw :halt, :target_event_reached if @number_of_events == @major_events
    end
  end

  def to_a
    @event_log
  end
end
