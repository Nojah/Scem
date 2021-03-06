class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name
      t.text :description
      t.boolean :to_display

      t.timestamps
    end
  end

  def self.down
    drop_table :categories
  end
end
