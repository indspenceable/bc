class AddMetadataToUser < ActiveRecord::Migration
  def change
    add_column :users, :metadata, :text
    User.all.each do |u|
      u.metadata = User.default_metadata
      u.save
    end
  end
end
