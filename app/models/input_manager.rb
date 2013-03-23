# Input manager manages input.

class InputManager
  attr_reader :input_counter, :can_cancel
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
    @can_cancel = [player_id]
  end
  def require_multi_input!(*args)
    raise "Didn't answer previous question" if input_required?
    @can_cancel = []
    @required_input = Hash.new{|h,k| h[k] = []}
    @answers = {}
    args.each_slice(2) do |str_validator_callback_pair|
      str_validator_callback_pair.each_with_index do |str_validator_callback, index|
        @required_input[index] << str_validator_callback
      end
    end
    answer_inputs!
    @can_cancel = []
  end
  def required_input
    Hash[@required_input.select{|k,v| v.any?}.map do |k,v|
      [k, v.first.first]
    end]
  end
  def answer(player_id)
    @answers[player_id]
  end

  def stop_cancels!
    @can_cancel = []
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
        concede!(k) if v[0] == "concede"
        raise "#{k} sent input (#{v}) when it wasn't needed." if v.any?
      end
      throw :halt, :input_required
    end
    @answers
  end
  def concede!(player_id)
    @required_input = {}
    @input_counter += 1
    throw :halt, [:concede, (player_id+1)%2]
  end
  def answer!(player_id, string)
    raise "We weren't asking that player for anything." unless @required_input[player_id].any?
    question, validator, callback = @required_input[player_id].shift
    concede!(player_id) if string == "concede"
    raise "Invalid answer \"#{string}\" to #{question}" unless validator.call(string)
    @input_counter+=1
    @answers[player_id] = string.downcase
    callback.call(@answers[player_id]) if callback
    @can_cancel << player_id
    @answers[player_id]
  end
  def input_required?
    # @required_input.keys.any?{|k| !@answers.key?(k) }
    @required_input.any?{ |k,v| v.any? }
  end
end
