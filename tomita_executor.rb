require 'unicode_utils'
require 'json'

class TomitaExecutor
  #TODO: config.yml?/?
  TOMITA_PATH = '/home/mike/GradWork/AnalyzeNews'
  TOMITA_EXECUTABLE = 'tomita-linux64'
  TOMITA_CONFIG = 'config.proto'

  def self.execute path
    `cd #{TOMITA_PATH} && ./#{TOMITA_EXECUTABLE} #{TOMITA_CONFIG} < #{path}`
  end
end
