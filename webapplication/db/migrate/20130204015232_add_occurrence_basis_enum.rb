class AddOccurrenceBasisEnum < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TYPE occurrence_basis AS ENUM(
        'Preserved specimen',
        'Human observation',
        'Machine observation'
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP TYPE IF EXISTS occurrence_basis;
    SQL
  end
end
