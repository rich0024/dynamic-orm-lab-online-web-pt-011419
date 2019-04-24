require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def initialize(attributes = {})
    attributes.each do |property, value|
    self.send("#{property}=", value)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    table_info.collect do |row|
      row["name"]
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    col_names_for_insert.split(", ").map do |col_name|
      "'#{send(col_name)}'" unless send(col_name).nil?
    end.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attributes = {})
    where_clause = []
    attributes.each do |key, value|
      formatted_value = value.class == String ? "'#{value}'" : value
      where_clause << "#{key} = #{formatted_value}"
    end
    sql = "SELECT * FROM #{self.table_name} WHERE ?"
    DB[:conn].execute(sql, where_clause.join(", "))
  end

end
