class CreatingModels < ActiveRecord::Migration
  def change
    create_table :hits do |t|
      t.string :ip_address

      t.timestamps
    end

    create_table :comments do |t|
      t.text :body
      t.string :name
      
      t.timestamps
    end



  end
end
