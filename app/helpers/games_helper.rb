module GamesHelper
  def game_badges(game)
    badges = {}
    badges["Input Required"] = :info if game.play.required_input[game.player_id(current_user)]
    badges
  end
end
