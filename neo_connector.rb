require 'neography'

class NeoConnector
  #TODO: config.yml
  @@neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "root"})

  def self.create_location location
    begin
      unless location.empty?
        checking_query = "match(n:Location:#{location[:type]}) where n.name = \'#{location[:name].gsub("'", %q(\\\'))}\' AND n.lat = #{location[:lat]} AND n.lng = #{location[:lng]} return n.uuid"
        checking_data = @@neo.execute_query(checking_query)['data']
        if checking_data.empty?
          create_query = "Create (n:Location:#{location[:type]}{uuid: \'#{location[:uuid]}\',name: \'#{location[:name].gsub("'", %q(\\\'))}\', lat: #{location[:lat]}, lng: #{location[:lng]}})"
          # p create_query
          @@neo.execute_query create_query
          location[:uuid]
        else
          checking_data[0][0]
        end
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.create_article_location_connection location_uuid, article_uuid
    begin
      checking_query = "Match (n:Location)-[r:noted_in]->(m:Article) WHERE n.uuid=\'#{location_uuid}\' AND m.uuid=\'#{article_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:Location),(m:Article) WHERE n.uuid=\'#{location_uuid}\' AND m.uuid=\'#{article_uuid}\' create (n)-[r:noted_in]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.get_location_uuid name
    begin
      checking_query = "match(n:Location) where n.name = \'#{name.gsub("'", %q(\\\'))}\' return n.uuid"
      checking_data = @@neo.execute_query(checking_query)['data']
      unless checking_data.empty?
        checking_data[0][0]
      else
        nil
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.get_location uuid
    begin
      location_query = "match(n:Location) where n.uuid = \'#{uuid}\' return n.uuid, n.name, n.lat, n.lng, labels(n)[1]"
      location_data = @@neo.execute_query(location_query)['data']
      unless location_data.empty?
        location_data[0]
      else
        {}
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.search_location_cachehit location_name, location_type
    begin
      location_query = "match(n:#{location_type}) where n.name = \'#{location_name.gsub("'", %q(\\\'))}\' return n.uuid, n.name, n.lat, n.lng"
      location_data = @@neo.execute_query(location_query)['data']
      unless location_data.empty?
        {
          uuid: location_data[0][0],
          name: location_data[0][1],
          lat: location_data[0][2],
          lng: location_data[0][3]
        }
      else
        {}
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.match_article_uuid uuid
    begin
      checking_query = "match(n:Article) where n.uuid = \'#{uuid}\' return n.uuid"
      checking_data = @@neo.execute_query(checking_query)['data']
      checking_data.empty?
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_region_and_country region_uuid, country_uuid
    begin
      checking_query = "Match (n:Region)-[r:part_of]->(m:Country) WHERE n.uuid=\'#{region_uuid}\' AND m.uuid=\'#{country_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:Region),(m:Country) WHERE n.uuid=\'#{region_uuid}\' AND m.uuid=\'#{country_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_subregion_and_country subregion_uuid, country_uuid
    begin
      checking_query = "Match (n:Subregion)-[r:part_of]->(m:Country) WHERE n.uuid=\'#{subregion_uuid}\' AND m.uuid=\'#{country_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:Subregion),(m:Country) WHERE n.uuid=\'#{subregion_uuid}\' AND m.uuid=\'#{country_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_subregion_and_region subregion_uuid, region_uuid
    begin
      checking_query = "Match (n:Subregion)-[r:part_of]->(m:Region) WHERE n.uuid=\'#{subregion_uuid}\' AND m.uuid=\'#{region_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:Subregion),(m:Region) WHERE n.uuid=\'#{subregion_uuid}\' AND m.uuid=\'#{region_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_city_and_subregion city_uuid, subregion_uuid
    begin
      checking_query = "Match (n:City)-[r:part_of]->(m:Subregion) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{subregion_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:City),(m:Subregion) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{subregion_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_city_and_region city_uuid, region_uuid
    begin
      checking_query = "Match (n:City)-[r:part_of]->(m:Region) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{region_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:City),(m:Region) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{region_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

  def self.connect_city_and_country city_uuid, country_uuid
    begin
      checking_query = "Match (n:City)-[r:part_of]->(m:Country) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{country_uuid}\' return r"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Match (n:City),(m:Country) WHERE n.uuid=\'#{city_uuid}\' AND m.uuid=\'#{country_uuid}\' create (n)-[r:part_of]->(m)"
        @@neo.execute_query create_query
        true
      else
        false
      end
    rescue Neography::SyntaxException => e
      p e
    end
  end

end
