require 'geocoder'
require 'json'
require 'neography'
require 'yaml'
require 'set'
require 'cgi'
require 'open-uri'
require 'json'
require 'securerandom'
load File.expand_path('../country.rb', __FILE__)
load File.expand_path('../region.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)

# Config.yml
Geocoder.configure(always_raise: [Geocoder::OverQueryLimitError])
Geocoder.configure(language: :ru)
Geocoder.configure(api_key: "AIzaSyBq7qgARXTDMAGCVWAiUDXzcTN4mU4B4FY")
Geocoder.configure(timeout: 10)


class PlacesAnalyzer
  GEONAMES_SEARCH_URI = 'http://api.geonames.org/searchJSON?'
  GEONAMES_SEARCH_PARAMS = {
    formatted: true,
    maxRows: 10,
    username: 'mikesehse',
    lang: 'ru',
    search_lang: 'ru',
    orderby: 'relevance',
    style: 'full'
  }
  PLACES_PREFIXES = YAML.load_file(File.expand_path('../location_prefixes.yml',__FILE__))
  PLACES_PREFIXES_LOOKUP_SET = Set.new(PLACES_PREFIXES.flat_map{|k,v| v.flat_map{|k1, v1| v1}}.reduce(:merge).flat_map{|k, v| (v<<k)})
  PLACES_TYPES = {
    'country' => 'Country',
    'locality' => 'City',
    'administrative_area_level_1' => 'Region',
    'administrative_area_level_2' => 'Subregion'
  }
  PLACES_QUERY_PARAMS = {
    'Country' => '&featureCode=PCLI&',
    'City' => '&featureClass=P&',
    'Region' => '&featureCode=ADM1&',
    'Subregion' => '&featureCode=ADM2&featureCode=ADM3&',
    'default' => '&'
  }

  def self.locate_place name
    geocoder_response = Geocoder.search(name)
    geocoder_response.map do |data|
      result = data.data
      components = result['address_components']
      point = Hash.new
      point[:lat] = result['geometry']['location']['lat']
      point[:lng] = result['geometry']['location']['lng']
      places = components.select{|x| (x['types'] & PLACES_TYPES.keys).length > 0}.compact
      unless places.empty?
        place = places.first
        point[:type] = place['types'].map{|x| PLACES_TYPES[x]}.compact.first
        point[:name] = place['long_name']
        parents = places[1..-1]
        point[:parents] = Hash.new
        parents.each do |parent|
          parent_name = parent['long_name']
          unless parent_name.include? point[:name]
            type = PLACES_TYPES[(parent['types'] & PLACES_TYPES.keys).first].downcase.to_sym
            point[:parents][type] = parent['long_name']
          end
        end
      else
        point = nil
      end
      point
    end
  end

  def self.locate_country name
    cachehit = NeoConnector.search_location_cachehit name, 'Country'
    if cachehit.keys.empty?
      query = build_geonames_query name, 'Country'
      geonames_response = JSON.parse(open(query).read)
      if geonames_response['totalResultsCount'] > 0
        result = {}
        country_data = geonames_response['geonames'].first
        result[:uuid] = SecureRandom.uuid
        russian_name = country_data['name'] ||  country_data['alternateNames'].select{|x| x['lang'] == 'ru'}.first
        if russian_name
          result[:name] = russian_name['name'] || name
        else
          result[:name] = name
        end
        result[:lat] = country_data['lat'].to_f
        result[:lng] = country_data['lng'].to_f
        Country.new result
      else
        nil
      end
    else
      Country.new(cachehit.merge({encached: true}))
    end
  end

  def self.locate_region name
    cachehit = NeoConnector.search_location_cachehit name, 'Region'
    if cachehit.keys.empty?
      query = build_geonames_query name, 'Region'
      geonames_response = JSON.parse(open(query).read)
      if geonames_response['totalResultsCount'] > 0
        result = {}
        region_data = geonames_response['geonames'].first
        result[:uuid] = SecureRandom.uuid
        russian_name = region_data['name'] || region_data['alternateNames'].select{|x| x['lang'] == 'ru'}.first
        if russian_name
          result[:name] = russian_name['name'] || name
        else
          result[:name] = name
        end
        result[:lat] = region_data['lat'].to_f
        result[:lng] = region_data['lng'].to_f
        Region.new result
      else
        nil
      end
    else
      Region.new(cachehit.merge({encached: true}))
    end
  end

  def self.locate_subregion name
    cachehit = NeoConnector.search_location_cachehit name, 'Subregion'
    if cachehit.keys.empty?
      query = build_geonames_query name, 'Subregion'
      geonames_response = JSON.parse(open(query).read)
      if geonames_response['totalResultsCount'] > 0
        result = {}
        subregion_data = geonames_response['geonames'].first
        result[:uuid] = SecureRandom.uuid
        russian_name = subregion_data['name'] || subregion_data['alternateNames'].select{|x| x['lang'] == 'ru'}.first
        if russian_name
          result[:name] = russian_name['name'] || name
        else
          result[:name] = name
        end
        result[:lat] = subregion_data['lat'].to_f
        result[:lng] = subregion_data['lng'].to_f
        Subregion.new result
      else
        nil
      end
    else
      Subregion.new(cachehit.merge({encached: true}))
    end
  end

  def self.city_candidates name
    query = build_geonames_query name, 'City'
    geonames_response = JSON.parse(open(query).read)
    if geonames_response['totalResultsCount'] > 0
      city_data = geonames_response['geonames']
      city_data.map do |city|
        result = {}
        russian_name = city['name'] || city['alternateNames'].select{|x| x['lang'] == 'ru'}.first
        if russian_name
          result[:name] = russian_name['name'] || name
        else
          result[:name] = name
        end
        result[:country] = city['countryName']
        result[:region] = city['adminName1']
        if result[:region] == "МО" && result[:country] == "Россия"
          result[:region] = "Московская область"
        end
        result[:lat] = city['lat'].to_f
        result[:lng] = city['lng'].to_f
        result
      end
    else
      []
    end
  end

  def self.build_geonames_query name, type='default', params = {}
    query_params = params.merge(GEONAMES_SEARCH_PARAMS).map{|k,v| "#{k}=#{v}"}.join("&")
    GEONAMES_SEARCH_URI + "&name=#{CGI.escape(name)}" + "#{PLACES_QUERY_PARAMS[type]}" + query_params
  end

  def self.normalize_prefix(prefix)
    norms = PLACES_PREFIXES.flat_map{|k,v| v.flat_map{|k1, v1| v1}}.reduce(:merge)
    norms.select{|k, v| (v<<k).include? prefix}.first.first
  end

end
