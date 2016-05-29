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
  CITY_WITH_REGION_REGEX = /(?<=^\t\tRegion\s\=\s)(.*)(?:\s*\n)\s*City\s\=\s(.*)\s*\n\s*\}/
  CITY_WITH_COUNTRY_REGEX = /(?<=^\t\tCountry\s\=\s)(.*)(?:\s*\n)\s*City\s\=\s(.*)\s*\n\s*\}/
  LOCATION_REGEX = Regexp.union(COUNTRY_REGEX, CITY_REGEX, REGION_REGEX, SUBREGION_REGEX, SOME_LOCATION_REGEX, CITY_WITH_REGION_REGEX, CITY_WITH_COUNTRY_REGEX)

  STOP_WORDS = File.open(File.expand_path('../stop_words.txt', __FILE__), 'r') do |file|
    file.read.split "\n"
  end

  def initialize path
    @path = path
    output = TomitaExecutor.execute(path)
    @frequencies = sort_frequency(simple_parse(output))
    @near_ones = output.split('.').map{|x| flat_parse(x)}.select{|x| !x.empty?}
    countries = output.scan(COUNTRY_REGEX).flatten.select{|x| !STOP_WORDS.include? x}
    cities = output.scan(CITY_REGEX).flatten.select{|x| !STOP_WORDS.include? x}
    regions = output.scan(REGION_REGEX).flatten.select{|x| !STOP_WORDS.include? x}
    subregions = output.scan(SUBREGION_REGEX).flatten.select{|x| !STOP_WORDS.include? x}
    others = output.scan(SOME_LOCATION_REGEX).flatten.select{|x| !STOP_WORDS.include? x}
    city_regions = output.scan(CITY_WITH_REGION_REGEX).select{|x| x.map{|y| STOP_WORDS.include?(y) ? nil : y}}
    city_countries = output.scan(CITY_WITH_COUNTRY_REGEX).select{|x| x.map{|y| STOP_WORDS.include?(y) ? nil : y}}
    @names_by_type = {
      countries: countries.uniq,
      cities: cities.uniq,
      regions: regions.uniq,
      subregions: subregions.uniq,
      others: others.uniq,
      city_regions: city_regions.uniq,
      city_countries: city_countries.uniq
    }
    @typed_names = [
      others.flat_map{|x| {x => 'Some_Location'}}.reduce(:merge),
      countries.flat_map{|x| {x=> 'Country'}}.reduce(:merge),
      regions.flat_map{|x| {x=> 'Region'}}.reduce(:merge),
      subregions.flat_map{|x| {x=> 'Subregion'}}.reduce(:merge),
      cities.flat_map{|x| {x => 'City'}}.reduce(:merge),
      city_regions.map{|x| {x[1] => 'City', x[0] => 'Region'}}.reduce(:merge),
      city_countries.map{|x| {x[1] => 'City', x[0] => 'Country'}}.reduce(:merge)
    ].compact.reduce(:merge)

  end

  def to_h
    {
      path: @path,
      frequencies: @frequencies,
      near_ones: @near_ones,
      typed_names: @typed_names,
      names_by_type: @names_by_type,
    }
  end

  def flat_parse text
    countries = text.scan(COUNTRY_REGEX).flatten.uniq.map{|x| [x,'Country']}
    cities = text.scan(CITY_REGEX).flatten.uniq.map{|x| [x,'City']}
    regions = text.scan(REGION_REGEX).flatten.uniq.map{|x| [x,'Region']}
    subregions = text.scan(SUBREGION_REGEX).flatten.uniq.map{|x| [x,'Subregion']}
    others = text.scan(SOME_LOCATION_REGEX).flatten.uniq.map{|x| [x,'Some_Location']}
    city_regions = text.scan(CITY_WITH_REGION_REGEX).map{|x| [[x[1], 'City'], [x[0], 'Region']]}
    city_countries = text.scan(CITY_WITH_COUNTRY_REGEX).map{|x| [[x[1], 'City'], [x[0], 'Country']]}
    countries + cities + regions + subregions + others + city_regions + city_countries
  end

  def simple_parse text
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
