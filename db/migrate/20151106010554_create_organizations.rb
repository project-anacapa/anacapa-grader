class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.belongs_to :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
