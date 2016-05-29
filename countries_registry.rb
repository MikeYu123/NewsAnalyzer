require 'yaml'

class CountriesRegistry
  COUNTRIES = YAML.load_file(File.expand_path('../countries.yml', __FILE__))

  # def self.has?(name)
  #   COUNTRIES.has_key? name || COUNTRIES['Doubles'].has_key?(name)
  # end
  #
  # def self.country_name(alias_name)
  #   COUNTRIES.select{|country| get_aliases(country).contains? alias_name}.first.last
  # end

  def self.find_double(name1, name2)
    double = COUNTRIES['Doubles'].select{|k,v| v.include?(name1) && v.include?(name2)}.first
    if double
      double.first
    else
      nil
    end
  end
end
