require 'active_support'
require 'active_support/core_ext'
load File.expand_path('../tomita_analysis.rb', __FILE__)
load File.expand_path('../neo_connector.rb', __FILE__)
load File.expand_path('../places_analyzer.rb', __FILE__)
load File.expand_path('../countries_registry.rb', __FILE__)
load File.expand_path('../city.rb', __FILE__)
load File.expand_path('../country.rb', __FILE__)
load File.expand_path('../region.rb', __FILE__)
load File.expand_path('../subregion.rb', __FILE__)

class ArticleAnalyzer

  #TODO: config.yml???
  ROOT_PATH = '/home/mike/GradWork/AnalyzeNews/'
  FIRST_WORD_TOKEN_REG = /^(([А-Я]*[\.\x20\-]?)*)(?=[\,\x20\n])/
  RUSSIAN_REG = /[А-Яа-я\x20\-]*/

  #TODO: Self???
  def self.analyze_article article

    if article['body']

      body = try_first_word(article['body'])

      uuid = article['uuid']

      file_name, dir_name = create_tmp_file(uuid)

      File.open(file_name, 'w') do |file|
        file.write article['body']
      end

      analysis_results = analyze_from_file file_name

      analysis_results.each{|x| x.connect_to_article uuid}

      File.delete file_name
      Dir.rmdir dir_name
    end
  end

  def self.analyze_from_file file
    tomita_results = TomitaAnalysis.new(file)
    # Если несколько Some_Location рядом - рассматриваем отдельно
    all_results = tomita_results.frequencies.keys
    matching_data = all_results.map{|x| x.mb_chars.downcase.to_s}
    double_hits = []

    double_candidates = tomita_results.names_by_type[:others].map do |other_1|
      tomita_results.names_by_type[:others].map do |other_2|
        double_candidate = CountriesRegistry.find_double(other_1, other_2)
        if double_candidate
          double_hits << other_1
          double_hits << other_2
        end
      end
    end

    double_hits = double_hits.uniq

    double_candidates = double_candidates.flatten.compact
    others = tomita_results.names_by_type[:others].map{|x| x.mb_chars.capitalize.to_s}.uniq - double_hits

    double_candidates.map! do |result|
      search_result = PlacesAnalyzer.locate_place(result).first
      cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Country')
      object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
      Country.new object_data
    end

    countries = tomita_results.names_by_type[:countries].map do |result|
      search_result = PlacesAnalyzer.locate_place(result).first
      if search_result
        cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Country')
        object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
        Country.new object_data
      end
    end

    regions = tomita_results.names_by_type[:regions].map do |result|
      search_result = PlacesAnalyzer.locate_place(result).first
      if search_result
        cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Region')
        object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
        object = Region.new object_data
        if search_result[:parents][:country]
          region_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
          if region_country
            unless region_country.encached
              region_country.to_neo4j
            end
            object.country = region_country
          end
        end
        unless object.encached
          object.to_neo4j
        end
        object
      end
    end

    subregions = tomita_results.names_by_type[:subregions].map do |result|
      search_result = PlacesAnalyzer.locate_place(result).first
      cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Subregion')
      object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
      object = Subregion.new object_data
      if search_result[:parents][:region]
        subregion_region = PlacesAnalyzer.locate_region search_result[:parents][:region]
        if subregion_region
          unless subregion_region.encached
            subregion_region.to_neo4j
          end
          object.region = subregion_region
        end
      end
      if search_result[:parents][:country]
        subregion_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
        if subregion_country
          unless subregion_country.encached
            subregion_country.to_neo4j
          end
          object.country = subregion_country
          if object.region
            object.region.country = object.country
            object.region.to_neo4j
          end
        end
      end
      unless object.encached
        object.to_neo4j
      end
      object
    end

    cities = tomita_results.names_by_type[:cities].map do |result|
      # remove some extra stuff
      geonames_name = result.split(' ').select{|token| !PlacesAnalyzer::PLACES_PREFIXES_LOOKUP_SET.member?(token)}.join(' ')
      candidates = PlacesAnalyzer.city_candidates(geonames_name)
      unless candidates.empty?
        highest_score = 0
        if candidates.length > 1
          candidates_score = candidates.map do |candidate|
            if matching_data.include? candidate[:region].mb_chars.downcase.to_s
              highest_score = 2
              [candidate, 2]
            elsif matching_data.include? candidate[:country].mb_chars.downcase.to_s
              highest_score = 1 > highest_score ? 1 : highest_score
              [candidate, 1]
            else
              [candidate, 0]
            end
          end
          chosen_one = candidates_score.select{|c_s| c_s[1] == highest_score}.first[0]
          query = case highest_score
          when 2
            chosen_one[:name] + ', ' + chosen_one[:region]
          when 1
            chosen_one[:name] + ', ' + chosen_one[:country]
          else
            chosen_one[:name]
          end
        else
          # query = candidates[0][:name]
          # Здесь мы возвращаем пометку типа "регион", "город" и т.д., т.к. это улрощает поиск в Google Geocoding
          query = result
        end
      else
        query = result
      end
      query

      search_result = PlacesAnalyzer.locate_place(query).first
      object = City.new search_result
      if search_result[:parents][:subregion]
        city_subregion = PlacesAnalyzer.locate_subregion search_result[:parents][:subregion]
        if city_subregion
          unless city_subregion.encached
            city_subregion.to_neo4j
          end
          object.subregion = city_subregion
        end
      end
      if search_result[:parents][:region]
        city_region = PlacesAnalyzer.locate_region search_result[:parents][:region]
        if city_region
          unless city_region.encached
            city_region.to_neo4j
          end
          object.region = city_region
          if object.subregion
            object.subregion.region = object.region
            object.subregion.to_neo4j
          end
        end
      end
      if search_result[:parents][:country]
        city_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
        if city_country
          unless city_country.encached
            city_country.to_neo4j
          end
          object.country = city_country
          if object.subregion
            object.subregion.country = object.country
            object.subregion.to_neo4j
          end
          if object.region
            object.region.country = object.country
            object.region.to_neo4j
          end
        end
      end
      unless object.encached
        object.to_neo4j
      end
      object
    end

    others = others.map do |result|
      search_result = PlacesAnalyzer.locate_place(result)[0]
      if search_result
        location = case search_result[:type]
        when 'Country'
          cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Country')
          object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
          object = Country.new object_data
          object
        when 'Region'
          search_result = PlacesAnalyzer.locate_place(result).first
          cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Region')
          object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
          object = Region.new object_data
          if search_result[:parents][:country]
            region_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
            if region_country
              unless region_country.encached
                region_country.to_neo4j
              end
              object.country = region_country
            end
          end
          unless object.encached
            object.to_neo4j
          end
          object
        when 'Subregion'
          search_result = PlacesAnalyzer.locate_place(result).first
          cachehit = NeoConnector.search_location_cachehit(search_result[:name], 'Subregion')
          object_data = cachehit.keys.empty? ? search_result : cachehit.merge({encached: true})
          object = Subregion.new object_data
          if search_result[:parents][:region]
            subregion_region = PlacesAnalyzer.locate_region search_result[:parents][:region]
            if subregion_region
              unless subregion_region.encached
                subregion_region.to_neo4j
              end
              object.region = subregion_region
            end
          end
          if search_result[:parents][:country]
            subregion_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
            if subregion_country
              unless subregion_country.encached
                subregion_country.to_neo4j
              end
              object.country = subregion_country
              if object.region
                object.region.country = object.country
                object.region.to_neo4j
              end
            end
          end
          unless object.encached
            object.to_neo4j
          end
          object
        when 'City'
          object = City.new search_result
          if search_result[:parents][:subregion]
            city_subregion = PlacesAnalyzer.locate_subregion search_result[:parents][:subregion]
            if city_subregion
              unless city_subregion.encached
                city_subregion.to_neo4j
              end
              object.subregion = city_subregion
            end
          end
          if search_result[:parents][:region]
            city_region = PlacesAnalyzer.locate_region search_result[:parents][:region]
            if city_region
              unless city_region.encached
                city_region.to_neo4j
              end
              object.region = city_region
              if object.subregion
                object.subregion.region = object.region
                object.subregion.to_neo4j
              end
            end
          end
          if search_result[:parents][:country]
            city_country = PlacesAnalyzer.locate_country search_result[:parents][:country]
            if city_country
              unless city_country.encached
                city_country.to_neo4j
              end
              object.country = city_country
              if object.subregion
                object.subregion.country = object.country
                object.subregion.to_neo4j
              end
              if object.region
                object.region.country = object.country
                object.region.to_neo4j
              end
            end
          end
          unless object.encached
            object.to_neo4j
          end
          object
        end
      end
    end

    [countries, regions, subregions, cities, double_candidates, others].flatten.compact
  end

  # Многие репортажи начнажтся с названия города в верхнем регистре и даты
  def self.try_first_word(text)
    return text.gsub FIRST_WORD_TOKEN_REG do |match|
      match.split(' ').map{|x| x.mb_chars.capitalize.to_s}.join('-')
    end
  end

  def self.create_tmp_file uuid
    dir_name = ROOT_PATH + 'tmp-' + uuid
    begin
      Dir.mkdir(dir_name)
    rescue Errno::EEXIST
    end
    file_name = dir_name + '/article.txt'
    [file_name, dir_name]
  end


end
