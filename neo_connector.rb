require 'neography'
class NeoConnector
  #TODO: config.yml
  @@neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "root"})
  def self.create_location location
    unless location.empty?
      checking_query = "match(n:Location:#{location[:type]}) where n.name = \'#{location[:name]}\' AND n.lat = #{location[:lat]} AND n.lng = #{location[:lng]} return n.uuid"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Create (n:Location:#{location[:type]}{uuid: \'#{location[:uuid]}\',name: \'#{location[:name]}\', lat: #{location[:lat]}, lng: #{location[:lng]}})"
        @@neo.execute_query create_query
        location[:uuid]
      else
        checking_data[0][0]
      end
    end
  end

  def self.create_article_location_connection location_uuid, article_uuid
    create_query = "Match (n:Location),(m:Article) WHERE n.uuid=\'#{location_uuid}\' AND m.uuid=\'#{article_uuid}\' create (n)-[r:noted_in]->(m)"
    p create_query
    @@neo.execute_query create_query
  end

  def self.get_location_uuid name
    checking_query = "match(n:Location) where n.name = \'#{name}\' return n.uuid"
    checking_data = @@neo.execute_query(checking_query)['data']
    unless checking_data.empty?
      checking_data[0][0]
    else
      nil
    end
  end

end
