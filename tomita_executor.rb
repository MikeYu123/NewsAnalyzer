require 'unicode_utils'
require 'json'

class TomitaExecutor
  LOCATION_REGEX = /(?<=^\t\tCountry\s\=\s)(.*)(?=\s)/
  TOMITA_PATH = './'
  TOMITA_EXECUTABLE = 'tomita-linux64'
  TOMITA_CONFIG = 'config.proto'


  def self.parse_output output
    locations = output.scan(LOCATION_REGEX).flatten.select{|x| UnicodeUtils.uppercase_char? x[0]}.uniq
  end

  def self.parse path
    output = `cd #{TOMITA_PATH} && ./#{TOMITA_EXECUTABLE} #{TOMITA_CONFIG} < #{path}`
    parse_output output
  end
end
