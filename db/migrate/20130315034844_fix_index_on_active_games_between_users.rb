class FixIndexOnActiveGamesBetweenUsers < ActiveRecord::Migration
  def up
    remove_index :games, name: :index_games_on_active_and_p0_id_and_p1_id
    add_index :games, [:active, :p0_id, :p1_id]
  end

  def down
    remove_index :games, name: :index_games_on_active_and_p0_id_and_p1_id
    add_index :games, [:active, :p0_id, :p1_id], unique: true
  end
end
