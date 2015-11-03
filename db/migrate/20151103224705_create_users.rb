class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer  "uid",                        null: false
      t.string   "token",                      null: false
      t.datetime "created_at",                 null: false
      t.datetime "updated_at",                 null: false
      t.boolean  "site_admin", default: false
    end
  end
end
