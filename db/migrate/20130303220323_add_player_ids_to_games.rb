class AddPlayerIdsToGames < ActiveRecord::Migration
  def change
    add_column :games, :p0_id, :integer
    add_column :games, :p1_id, :integer
    add_index :games, [:active, :p0_id, :p1_id], unique: true
  end
end
