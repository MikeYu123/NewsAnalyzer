require 'active_support'
require 'active_support/core_ext'
load File.expand_path('../tomita_executor.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../places_analyzer.rb', __FILE__)

class ArticleAnalyzer

  #TODO: config.yml???
  ROOT_PATH = '/home/mike/GradWork/AnalyzeNews/'
  FIRST_WORD_TOKEN_REG = /^(.+?)(?=[ ,])/

  #TODO: Self???
  def self.analyze_article article

    if article['body']

      body = article['body']
      try_first_word(body)
      uuid = article['uuid']

      ffile_name, dir_name = create_tmp_file(uuid)

      File.open(file_name, 'w') do |file|
        file.write article['body']
      end

      tomita_results = TomitaExecutor.parse(file_name)

      File.delete file_name
      Dir.rmdir dir_name

      tomita_results.each do |location|
        #TODO: Decompose it
        location_uuid = NeoConnector.get_location_uuid location
        unless location_uuid
          parsed_location = PlacesAnalyzer.locate_place location
          location_uuid = NeoConnector.create_location parsed_location
          if location_uuid
            NeoConnector.create_article_location_connection location_uuid, uuid
          end
        else
          NeoConnector.create_article_location_connection location_uuid, uuid
        end
      end
    end
  end

  # Многие репортажи начнажтся с названия города в верхнем регистре и даты
  def try_first_word(text)
    match_data = text.match(FIRST_WORD_TOKEN_REG)
    if match_data
      # Here comes token
      token = match_data[0]

      if token == token.mb_chars.upcase.to_s
        PlacesAnalyzer.analyze_city_contender(token.mb_chars.capitalize.to_s)
      else
        nil
      end
    else
      return nil
    end
  end

  def self.create_tmp_file uuid
    dir_name = ROOT_PATH + 'tmp-' + uuid
    Dir.mkdir(dir_name)
    file_name = dir_name + '/article.txt'
    [file_name, dir_name]
  end


end
