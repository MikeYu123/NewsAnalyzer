require 'geocoder'
require 'json'
require 'neography'


class PlacesAnalyzer
  PLACES_TYPES = ['country', 'locality', 'administrative_area_level_1', 'administrative_area_level_2']
  def self.locate_place name
    google_response = Geocoder.search(name).first
    if google_response
      google_response_types = google_response.data['types'].select{|type| PLACES_TYPES.include? type}
      if google_response_types.length > 0
        google_response_type = google_response_types.first
        location = google_response.data['geometry']['location']
        neo_type = match_place_type(google_response_type)
        if neo_type.length > 0
          {
            uuid: SecureRandom.uuid,
            name: name,
            lat: location['lat'],
            lng: location['lng'],
            type: neo_type
          }
        else
          {

          }
        end
      else
        {}
      end
    else
      {}
    end
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
