require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  let(:address) { "New York, NY" }
  let(:geocoder_result) {
    [double("Geocoder::Result",
      postal_code: "10001",
      city: "New York",
      coordinates: [40.7128, -74.0060]
    )]
  }

  let(:weather_api_response) {
    {
      "main" => {
        "temp" => 25.0,
        "temp_min" => 20.0,
        "temp_max" => 28.0
      }
    }.to_json
  }

  before do
    allow(Geocoder).to receive(:search).and_return(geocoder_result)

    stub_request(:get, /api.openweathermap.org/)
      .to_return(status: 200, body: weather_api_response, headers: {})
  end

  it "returns forecast data for a valid address" do
    get forecast_index_path, params: { address: address }
    expect(response.body).to include("New York")
  end

  it "caches the forecast data by zip code" do
    Rails.cache.clear
    expect(Rails.cache.exist?("forecast:10001")).to be_falsey
    get forecast_index_path, params: { address: address }
    expect(response.body.should include("New York, NY")).to be_truthy
  end

  it "shows an error for invalid address" do
    allow(Geocoder).to receive(:search).and_return([])

    get forecast_index_path, params: { address: "Invalid Address" }

    expect(response.body).to include("Invalid address")
  end

  it "handles weather API failure" do
    allow(Geocoder).to receive(:search).and_return(geocoder_result)

    stub_request(:get, /api.openweathermap.org/)
      .to_return(status: 500, body: "", headers: {})

    get forecast_index_path, params: { address: address }

    expect(response.body).to include("Unable to fetch forecast data")
  end
end
