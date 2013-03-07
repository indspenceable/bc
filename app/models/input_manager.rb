# Input manager manages input.

class InputManager
  attr_reader :input_counter
  def initialize(input_buffer)
    @required_input = {}
    @input_buffer = Hash.new{|h, k| h[k] = []}
    input_buffer.each do |player_id, str|
      @input_buffer[player_id] << str
    end
    @input_counter = 0
  end
  def require_single_input!(player_id, input_string, validator)
    raise "Didn't answer previous question" if input_required?
    @input_counter+=1
    @answers = {}
    @required_input = Hash.new{|h,k| h[k] = []}
    @required_input[player_id] << [input_string, validator]
    answer_inputs!
  end
  def require_multi_input!(input_string, *validators_callback_pairs)
    raise "Didn't answer previous question" if input_required?

    validators = []
    on_answer_callbacks = []
    validators_callback_pairs.each do |a,b|
      validators << a
      on_answer_callbacks << b
    end

    @answers = {}
    @required_input = Hash.new{|h,k| h[k] = []}
    validators.each_with_index do |validator, idx|
      @required_input[idx % 2] <<  [input_string, validator, on_answer_callbacks[idx]]
    end
    answer_inputs!
  end
  def required_input
    Hash[@required_input.select{|k,v| v.any?}.map do |k,v|
      [k, v.first.first]
    end]
  end
  def answer(player_id)
    @answers[player_id]
  end

  private

  def answer_inputs!
    @required_input.each do |player_id, questions|
      questions.length.times do |q|
        if @input_buffer[player_id].any?
          answer!(player_id, @input_buffer[player_id].shift)
        end
      end
    end
    if input_required?
      @input_buffer.each do |k,v|
        raise "#{k} sent input (#{v}) when it wasn't needed." if v.any?
      end
      throw :input_required
    end
    @answers
  end
  def answer!(player_id, string)
    raise "We weren't asking that player for anything." unless @required_input[player_id].any?
    answer, validator, callback = @required_input[player_id].shift
    raise "Invalid answer \"#{string}\" to #{answer}" unless validator.call(string)
    @input_counter+=1
    @answers[player_id] = string.downcase
    callback.call(@answers[player_id]) if callback
    @answers[player_id]
  end
  def input_required?
    # @required_input.keys.any?{|k| !@answers.key?(k) }
    @required_input.any?{ |k,v| v.any? }
  end
end
