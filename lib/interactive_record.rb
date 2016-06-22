require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.tableize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    
    DB[:conn].execute("pragma table_info('#{table_name}')").map do |row|
      row["name"]
    end.compact
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  def initialize(attributes={})
    attributes.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})")
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = self.class.column_names.select do |col_name|
      self.send(col_name) != nil
    end.map do |col_name|
      "'#{self.send(col_name)}'"
    end.join(", ")
  end

  def self.find_by_name(name)
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = '#{name}'")
  end

  def self.find_by(pair={})
    DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{pair.keys[0]} = '#{pair.values[0]}'")
  end
end
