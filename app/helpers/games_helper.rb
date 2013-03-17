module GamesHelper
  def game_badges(game)
    badges = {}
    badges["Input Required"] = :info if game.play.required_input[game.player_id(current_user)]
    badges["Winner: #{game.play.winner}"] = :success if !game.play.active? && game.play.winner
    badges["Tie"] = :warning if !game.play.active? && game.play.tie
    badges
  end
  def character_badges(character_name)
    badges = {}
    badges["Beta"] = :warning if ['kehrolyn', 'hepzibah'].include?(character_name)
    badges
  end

  def badges(badges)
    badges.map do |badge, color|
      content_tag(:span, class: "label label-#{color}"){ badge }
    end.join("").html_safe
  end

  def game_string(game)
    players = game.play.characters
    flavor_str = "#{game.p0.name} #{players ? "(#{players[0].name.capitalize})" : ''} VS #{game.p1.name} #{players ? "(#{players[1].name.capitalize})" : ''}"
    link_str = link_to flavor_str, game_path(game)
    "#{link_str} #{badges(game_badges(game))}".html_safe
  end
end
