require 'pry'
class Dog
    attr_accessor :name, :breed, :id
 
    # def initialize (id: nil, name:, breed:)
    #     @id = id
    #     @name = name
    #     @breed = breed
    # end
    def initialize (attr_hash = {}) 
        attr_hash.each do |key, value|
            if self.respond_to?("#{key.to_s}=")
                self.send("#{key.to_s}=", value)
            end
        end
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER primary key,
            name TEXT,
            breed TEXT
        )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = " DROP TABLE IF EXISTS dogs "
        DB[:conn].execute(sql)
    end

    def save
        if !!self.id
            sql = <<-SQL 
            UPDATE dogs
            SET name = ?, breed = ?
            WHERE id = ?;
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].last_insert_row_id #execute("SELECT last_insert_rowid() FROM dogs")[0][0]
            self
        end
    end

    def self.create(attr_hash={})
        dog = self.new(attr_hash)
        dog.save
        dog
    end

    def self.new_from_db(attr_hash)
       id = attr_hash[0]
       name = attr_hash[1]
       breed = attr_hash[2]
       self.new(id: id, name: name, breed: breed)
    end

    def self.find_by_id(id)
        sql = "SELECT * FROM dogs WHERE id = ?"
        DB[:conn].execute(sql,id).map do |row|
            self.new_from_db(row)
          end.first
    end

    # def self.create(name:, breed:)
    #     dog = self.new(name: name, breed: breed)
    #     dog.save
    #     dog
    #   end
    
    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * 
        FROM dogs
        WHERE name = ?
        SQL
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def update 
        sql = <<-SQL
        UPDATE dogs
        SET name = ?, 
        breed = ?
        WHERE id = ?
        SQL
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

  
    def self.find_or_create_by(attr_hash)
        sql = <<-SQL
        SELECT * 
        FROM dogs 
        WHERE name = ?
        AND breed = ?
        SQL
        dog =  DB[:conn].execute(sql, attr_hash[:name], attr_hash[:breed])
        #binding.pry
        if !dog.empty?
            dog_attr = dog[0]
            
            dog = Dog.new(id: dog_attr[0], name: dog_attr[1], breed: dog_attr[2])
        else
            dog = self.create(attr_hash)
        end
    end
end