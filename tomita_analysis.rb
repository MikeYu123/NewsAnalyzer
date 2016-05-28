load File.expand_path('../tomita_executor.rb', __FILE__)

class TomitaAnalysis
  attr_accessor :path
  attr_accessor :frequencies
  attr_accessor :near_ones
  attr_accessor :typed_names
  attr_accessor :names_by_type
  COUNTRY_REGEX = /(?<=^\t\tCountry\s\=\s)(.*)(?=\s*\})/
  CITY_REGEX = /(?<=^\t\tCity\s\=\s)(.*)(?=\s*\})/
  REGION_REGEX = /(?<=^\t\tRegion\s\=\s)(.*)(?=\s*\})/
  SUBREGION_REGEX = /(?<=^\t\tSubregion\s\=\s)(.*)(?=\s*\})/
  SOME_LOCATION_REGEX = /(?<=^\t\tSome_Location\s\=\s)(.*)(?=\s*\})/
  CITY_WITH_REGION_REGEX = /(?<=^\t\tRegion\s\=\s)(?:\(\s*)(.*)(?:\s*\))\s*City\s\=\s(.*)\s*\}/
  LOCATION_REGEX = Regexp.union(COUNTRY_REGEX, CITY_REGEX, REGION_REGEX, SUBREGION_REGEX, SOME_LOCATION_REGEX, CITY_WITH_REGION_REGEX)

  def initialize path
    @path = path
    output = TomitaExecutor.execute(path)
    @frequencies = sort_frequency(flat_parse(output))
    @near_ones = output.split('.').map{|x| flat_parse(x)}.select{|x| !x.empty?}
    countries = output.scan(COUNTRY_REGEX).flatten
    cities = output.scan(CITY_REGEX).flatten
    regions = output.scan(REGION_REGEX).flatten
    subregions = output.scan(SUBREGION_REGEX).flatten
    others = output.scan(SOME_LOCATION_REGEX).flatten
    city_regions = output.scan(CITY_WITH_REGION_REGEX).flatten.MAP
    @names_by_type = {
      countries: countries,
      cities: cities,
      regions: regions,
      subregions: subregions,
      others: others,
      city_regions: city_regions
    }
    @typed_names = [
      others.flat_map{|x| {x => 'Some_Location'}}.reduce(:merge)
      countries.flat_map{|x| {x=> 'Country'}}.reduce(:merge),
      regions.flat_map{|x| {x=> 'Region'}}.reduce(:merge),
      subregions.flat_map{|x| {x=> 'Subregion'}}.reduce(:merge),
      cities.flat_map{|x| {x => 'City'}}.reduce(:merge),
      city_regions.flat_map{|x| {x[1] => 'City', x[0] => Region}}.reduce(:merge)
    ].compact.reduce(:merge)

  end

  def flat_parse text
    location_candidates = text.scan(LOCATION_REGEX).flatten.compact
  end

  def sort_frequency words
    result = {}
    words.each do |word|
      result[word] = result[word].to_i + 1
    end
    result.sort{|a, b| b[1] <=> a[1]}.to_h
  end
end
