require 'neography'
class NeoConnector
  #TODO: config.yml
  @@neo = Neography::Rest.new({:authentication => 'basic', :username => "neo4j", :password => "root"})
  def self.create_location location
    unless location.empty?
      query = "Create (n:Location:#{location[:type]}{name: \'#{location[:name]}\', lat: #{location[:lat]}, lng: #{location[:lng]}})"
      @@neo.execute_query query
    end
  end
end
