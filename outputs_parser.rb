require 'unicode_utils'
require 'json'

class TomitaExecutor
  COUNTRY_REGEX = /(?<=^\t\tCountry\s\=\s)(.*)(?=\s)/
  TOMITA_PATH = './'
  TOMITA_EXECUTABLE = 'tomita-linux64'
  TOMITA_CONFIG = 'config.proto'


  def self.parse_output output
    countries = output.scan(COUNTRY_REGEX).flatten.select{|x| UnicodeUtils.uppercase_char? x[0]}.uniq
    {
      countries: countries
    }.to_json
  end

  def self.parse path
    output = `cd #{TOMITA_PATH} && ./#{TOMITA_EXECUTABLE} #{TOMITA_CONFIG} < #{path}`
    parse_output output
  end
end
