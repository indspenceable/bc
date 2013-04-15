class RemoveStartingPlayerFromGames < ActiveRecord::Migration
  def change
    remove_column :games, :starting_player    
  end
end
