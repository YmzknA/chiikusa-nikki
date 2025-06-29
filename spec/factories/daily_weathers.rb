FactoryBot.define do
  factory :daily_weather do
    sequence(:date) { |n| Date.current - n.days }
    weather_data do
      {
        temperature: rand(15..35),
        humidity: rand(40..80),
        description: ["Sunny", "Cloudy", "Rainy", "Snowy"].sample,
        location: "Tokyo"
      }
    end

    trait :sunny do
      weather_data do
        {
          temperature: 25,
          humidity: 50,
          description: "Sunny",
          location: "Tokyo"
        }
      end
    end

    trait :rainy do
      weather_data do
        {
          temperature: 18,
          humidity: 85,
          description: "Rainy",
          location: "Tokyo"
        }
      end
    end
  end
end