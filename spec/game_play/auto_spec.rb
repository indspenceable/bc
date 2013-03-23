require 'spec_helper'
require "game_play"

def answer_input(g, pn)
  if g.required_input[pn] == "attack_pair_select"
    attack_pair(g,pn)
  elsif g.required_input[pn] =~ /select_from/
    select_from(g,pn)
  elsif g.required_input[pn] == "select_base_clash"
    select_base(g,pn)
  elsif g.required_input[pn] == "select_finisher"
    g.input!(pn, rand(2).to_s)
  else
    raise "Unknown input #{g.required_input[pn]}"
  end
end

def attack_pair(g, pn)
  p = g.instance_variable_get(:@players)[pn]
  b = p.bases.shuffle
  s = p.styles.shuffle
  g.input!(pn, "#{s.pop.name}_#{b.pop.name}")
end
def select_base(g, pn)
  p = g.instance_variable_get(:@players)[pn]
  b = p.bases.shuffle
  g.input!(pn, b.pop.name)
end

def select_from(g, pn)
  opts = g.required_input[pn].scan(/<[^>]*>/).map do |s|
    s[1, s.length-2]
  end
  selected = opts.shuffle.pop
  g.input!(pn, selected)
end

CHARACTER = ENV['CHARACTER']


describe GamePlay do
  (CHARACTER ? [CHARACTER] : GamePlay.character_names).each do |c1|
    GamePlay.character_names.each do |c2|
      it "doesn't raise errors when you give valid input in a #{c1} #{c2} game." do
        30.times do |i|
          g = GamePlay.new(i%2, ['p0', 'p1'])

          g.input!(0, c1)
          g.input!(1, c2)
          p0 = g.instance_variable_get(:@players)[0]
          p1 = g.instance_variable_get(:@players)[1]

          # first, select initial discards
          b0 = p0.bases.shuffle
          b1 = p1.bases.shuffle
          s0 = p0.styles.shuffle
          s1 = p1.styles.shuffle
          2.times do
            g.input!(0, "#{s0.pop.name}_#{b0.pop.name}")
            g.input!(1, "#{s1.pop.name}_#{b1.pop.name}")
          end

          while g.active?
            [nil, 0, 1].each{|i| g.game_state(i)}

            req = g.required_input
            if req[0]
              answer_input(g, 0)
            else
              answer_input(g, 1)
            end
          end
        end
      end
    end
  end
end
