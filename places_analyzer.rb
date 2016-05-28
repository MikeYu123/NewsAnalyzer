require 'geocoder'
require 'json'
require 'neography'
require 'yaml'
require 'set'

# Config.yml
Geocoder.configure(always_raise: [Geocoder::OverQueryLimitError])
Geocoder.configure(language: :ru)
Geocoder.configure(api_key: "AIzaSyBq7qgARXTDMAGCVWAiUDXzcTN4mU4B4FY")


class PlacesAnalyzer
  PLACES_PREFIXES = YAML.load_file(File.expand_path('../location_prefixes.yml',__FILE__))
  PLACES_LOOKUP_SET = Set.new(PLACES_PREFIXES.flat_map{|k,v| v.flat_map{|k1, v1| v1}}.reduce(:merge).flat_map{|k, v| (v<<k)})
  PLACES_TYPES = ['country', 'locality', 'administrative_area_level_1', 'administrative_area_level_2']
  def self.locate_place name
    # Geocoder.
  end

  def self.normalize_prefix(prefix)
    norms = PLACES_PREFIXES.flat_map{|k,v| v.flat_map{|k1, v1| v1}}.reduce(:merge)
    norms.select{|k, v| (v<<k).include? prefix}.first.first
  end

  def self.match_place_type place_type
    case place_type
    when 'country'
      "Country"
    when 'locality'
      "City"
    when 'administrative_area_level_1'
      "Region"
    when 'administrative_area_level_2'
      "Subregion"
    else
      "Dummy_type"
    end
  end
end
