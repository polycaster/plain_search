class CreateBaseTables < ActiveRecord::Migration
  def change

    create_table :companies do |t|
      t.string :name
    end

    create_table :employees do |t|
      t.belongs_to :company
      t.string :first_name
      t.string :last_name
      t.string :address
      t.string :zip_code
      t.string :city
      t.string :state
      t.string :phone
      t.string :email
      t.string :profession
    end

    create_table :dossiers do |t|
      t.string :filename
    end

    create_table :search_terms do |t|
      t.string :term, index: true
      t.string :source, index: true
      t.belongs_to :findable, polymorphic: true
    end

  end
end
