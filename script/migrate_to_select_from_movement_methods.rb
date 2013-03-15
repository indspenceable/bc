movement_methods = MOVEMENT_METHODS.map(&:to_s)
Game.transaction do
  Game.each do |g|
    inputs = g.inputs
    g.inputs = []
    play = g.play
    inputs.each do |pl, val|
      if val.include?('#')
        meth, arg = val.split('#')
        if movement_methods.include?(meth)
          play.input!(pl, play.characters[pl].send("#{meth}?", Integer(arg)).to_s)
          next
        end
      end
      play.input!(pl, val)
    end
    g.inputs = play.valid_inputs
    g.save!
  end
end
