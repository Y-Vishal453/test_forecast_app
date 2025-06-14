class ForecastController < ApplicationController
  def index
    return unless params[:address].present?
    # get geocoder address
    results = Geocoder.search(params[:address])
    if results.empty?
      flash[:error] = "Invalid address"
      return
    end
    # get zip_code and city from geocoder address
    zip_code = results.first.postal_code
    city = results.first.city

    cache_key = "forecast:#{zip_code}"
    forecast_data = Rails.cache.read(cache_key)

    if forecast_data
      @cached = true
    else
      lat = results.first.coordinates[0]
      lon = results.first.coordinates[1]
      response = HTTParty.get("https://api.openweathermap.org/data/2.5/weather?lat=#{lat}&lon=#{lon}&appid=#{WEATHER_API_KEY}&units=metric")
      
      if response.success?
        forecast_data = {
          temp: response['main']['temp'],
          temp_min: response['main']['temp_min'],
          temp_max: response['main']['temp_max']
        }
        # store in cache forecast data
        Rails.cache.write(cache_key, forecast_data)
        @cached = false
      else
        flash[:error] = "Unable to fetch forecast data"
        return
      end
    end

    @forecast = forecast_data
    @location = city || zip_code
  end
end
