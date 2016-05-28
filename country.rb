load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../countries_registry.rb', __FILE__)

class Country
  attr_accessor :name
  # nil-able: came with new updates
  attr_accessor :short_name
  attr_accessor :lat
  attr_accessor :lng
  attr_accessor :uuid
  attr_accessor :aliases

  def initialize params = {}
    @type = 'Country'
    @name = params[:name]
    @short_name = params[:short_name]
    @lat = params[:lat]
    @lng = params[:lng]
    @uuid = params[:uuid]
    @aliases = CountriesRegistry.get_aliases(name)
  end

  def self.from_neo4j uuid
    location_data = NeoConnector.get_location(uuid)
    {
      uuid: uuid,
      name: location_data[0],
      short_name: location_data[1],
      lat: location_data[2],
      lng: location_data[3]
    }
    new(location_data)
  end

  def location_data
    {
      uuid: @uuid,
      name: @name,
      short_name: @short_name,
      lat: @lat,
      lng: @lng,
      type: @type
    }
  end

  def to_neo4j
    NeoConnector.create_location(self.location_data)
  end

end
