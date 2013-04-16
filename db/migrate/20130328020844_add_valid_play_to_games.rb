class AddValidPlayToGames < ActiveRecord::Migration
  def change
    change_column :games, :valid_play, :boolean, :default => true
  end
end
