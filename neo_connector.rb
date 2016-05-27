require 'neography'
class NeoConnector
  #TODO: config.yml
  @@neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "root"})
  def self.create_location location
    unless location.empty?
      cap_letter = location[:name][0]
      rem_letters = location[:name][1..-1]
      query_name = "upper(\'#{cap_letter}\') + lower(\'#{rem_letters}\')"
      checking_query = "match(n:Location:#{location[:type]}) where n.name = #{query_name} AND n.lat = #{location[:lat]} AND n.lng = #{location[:lng]} return n.uuid"
      checking_data = @@neo.execute_query(checking_query)['data']
      if checking_data.empty?
        create_query = "Create (n:Location:#{location[:type]}{uuid: \'#{location[:uuid]}\',name: #{query_name}, lat: #{location[:lat]}, lng: #{location[:lng]}})"
        # p create_query
        @@neo.execute_query create_query
        location[:uuid]
      else
        checking_data[0][0]
      end
    end
  end

  def self.create_article_location_connection location_uuid, article_uuid
    checking_query = "Match (n:Location)-[r:noted_in]->(m:Article) WHERE n.uuid=\'#{location_uuid}\' AND m.uuid=\'#{article_uuid}\' return r"
    checking_data = @@neo.execute_query(checking_query)['data']

    if checking_data.empty?
      create_query = "Match (n:Location),(m:Article) WHERE n.uuid=\'#{location_uuid}\' AND m.uuid=\'#{article_uuid}\' create (n)-[r:noted_in]->(m)"
      @@neo.execute_query create_query
      true
    else
      false
    end
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

  def self.match_article_uuid uuid
    checking_query = "match(n:Article) where n.uuid = \'#{uuid}\' return n.uuid"
    checking_data = @@neo.execute_query(checking_query)['data']
    checking_data.empty?
  end
end
