load File.expand_path('../neo_connector.rb', __FILE__)
require 'securerandom'

class Country
  attr_accessor :name
  attr_accessor :lat
  attr_accessor :lng
  attr_accessor :uuid
  attr_accessor :type
  attr_accessor :encached

  def initialize params = {}
    @type = 'Country'
    @name = params[:name]
    @lat = params[:lat]
    @lng = params[:lng]
    @uuid = params[:uuid] || SecureRandom.uuid
    @encached = params[:encached] || false
  end

  def self.from_neo4j uuid
    location_data = NeoConnector.get_location(uuid)
    data = {
      uuid: location_data[0],
      name: location_data[1],
      lat: location_data[2],
      lng: location_data[3],
      type: location_data[4]
    }
    new(data)
  end

  def location_data
    {
      uuid: @uuid,
      name: @name,
      lat: @lat,
      lng: @lng,
      type: @type
    }
  end

  def to_neo4j
    @uuid = NeoConnector.create_location(self.location_data)
    @encached = true
    self
  end

  def connect_to_article article_uuid
    NeoConnector.create_article_location_connection @uuid, article_uuid
  end
end
