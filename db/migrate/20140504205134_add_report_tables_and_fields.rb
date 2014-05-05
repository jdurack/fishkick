class AddReportTablesAndFields < ActiveRecord::Migration
  def change
    add_column :sites, :description, :string

    create_table :siteImage do |t|
      t.belongs_to :site
      t.string :image

      t.timestamps
    end

    create_table :fish do |t|
      t.string :name
      t.string :image

      t.timestamps
    end

    create_table :siteFishInfo do |t|
      t.belongs_to :site
      t.belongs_to :fish
      t.decimal :baseScoreJan, precision: 2, scale: 2
      t.decimal :baseScoreFeb, precision: 2, scale: 2
      t.decimal :baseScoreMar, precision: 2, scale: 2
      t.decimal :baseScoreApr, precision: 2, scale: 2
      t.decimal :baseScoreMay, precision: 2, scale: 2
      t.decimal :baseScoreJun, precision: 2, scale: 2
      t.decimal :baseScoreJul, precision: 2, scale: 2
      t.decimal :baseScoreAug, precision: 2, scale: 2
      t.decimal :baseScoreSep, precision: 2, scale: 2
      t.decimal :baseScoreOct, precision: 2, scale: 2
      t.decimal :baseScoreNov, precision: 2, scale: 2
      t.decimal :baseScoreDec, precision: 2, scale: 2

      t.timestamps
    end

    create_table :fishScore do |t|
      t.belongs_to :site
      t.belongs_to :fish
      t.datetime :date

      t.timestamps
    end
  end
end
