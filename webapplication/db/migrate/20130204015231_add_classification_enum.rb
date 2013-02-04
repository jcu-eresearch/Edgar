class AddClassificationEnum < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TYPE classification AS ENUM(
          'unknown',
          'invalid',
          'historic',
          'vagrant',
          'irruptive',
          'core',
          'introduced'
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE IF EXISTS classification;
    SQL
  end
end
