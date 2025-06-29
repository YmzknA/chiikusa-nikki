require "rails_helper"

RSpec.describe DailyWeather, type: :model do
  describe "validations" do
    subject { build(:daily_weather) }
    
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_uniqueness_of(:date) }
  end

  describe "factory validations" do
    it "creates valid daily_weather with factory" do
      daily_weather = build(:daily_weather)
      expect(daily_weather).to be_valid
    end

    it "validates date uniqueness" do
      create(:daily_weather, date: Date.current)
      duplicate_weather = build(:daily_weather, date: Date.current)
      
      expect(duplicate_weather).not_to be_valid
      expect(duplicate_weather.errors[:date]).to include("has already been taken")
    end
  end

  describe "JSON storage" do
    let(:weather_data) do
      {
        temperature: 25.5,
        humidity: 60,
        description: "Sunny",
        location: "Tokyo"
      }
    end

    it "stores and retrieves weather data as JSON" do
      daily_weather = create(:daily_weather, weather_data: weather_data)
      expect(daily_weather.weather_data["temperature"]).to eq(25.5)
      expect(daily_weather.weather_data["description"]).to eq("Sunny")
    end
  end
end