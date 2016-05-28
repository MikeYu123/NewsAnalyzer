require 'yaml'

class CountriesRegistry
  COUNTRIES = YAML.load_file('countries.yml')

  def self.get_aliases(name)
    if COUNTRIES.has_key? name
      return [COUNTRIES[name]].compact << name
    elsif COUNTRIES['Doubles'].has_key? name
      return [COUNTRIES['Doubles'][name]].compact << name
    else
      return []
    end
  end

  def self.has?(name)
    if COUNTRIES.has_key? name || COUNTRIES['Doubles'].has_key? name
  end

  def self.country_name(alias_name)
    COUNTRIES.select{|country| get_aliases(country).contains? alias_name}.first.last
  end

  def find_double(name1, name2)
    COUNTRIES['Doubles'].select{|k,v| v.include?(name1) && v.include?(name2)}.first.keys.first
  end
end
