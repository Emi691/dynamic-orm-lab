require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
 
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = <<-SQL
            PRAGMA table_info('#{self.table_name}')
            SQL
        table_pragma = DB[:conn].execute(sql)
        column_names = [] 
        table_pragma.collect{|column| column_names << column["name"] }
        column_names.compact
    end  

    def initialize(attr_hash = {})
        attr_hash.each do |property, value| 
        self.class.attr_accessor(property) 
        self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.drop(1).join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.collect do |column_name| 
            values << "'#{send(column_name)}'" unless send(column_name).nil?
        end
        #binding.pry
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert});"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM #{table_name} WHERE name = ?;
        SQL
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attribute)
        key = attribute.keys
        value = attribute[key.join.to_sym]
        #binding.pry
        sql = <<-SQL
        SELECT * FROM #{table_name} WHERE #{key.join} = '#{value}';
        SQL
        DB[:conn].execute(sql)
    end

end