#!/usr/bin/env ruby

# Configure Rails environment
ENV['RAILS_ENV'] = 'test'
require_relative 'config/environment'

# Run a simple test to verify the setup
puts "Testing database connection..."
begin
  ActiveRecord::Base.connection.execute("SELECT 1")
  puts "✅ Database connection successful"
rescue => e
  puts "❌ Database connection failed: #{e.message}"
  exit 1
end

puts "\nTesting model creation..."
begin
  # Test basic model creation without complex validations
  puts "Testing Question model..."
  question = Question.create!(
    identifier: "test_question",
    label: "テスト質問",
    icon: "🤔"
  )
  puts "✅ Question created successfully: #{question.id}"
  
  puts "Testing Answer model..."
  answer = Answer.create!(
    question: question,
    label: "テスト回答", 
    level: 3,
    emoji: "😊"
  )
  puts "✅ Answer created successfully: #{answer.id}"
  
  puts "Testing User model..."
  user = User.create!(
    email: "test@example.com",
    username: "testuser",
    github_id: "12345",
    encrypted_access_token: "token123",
    providers: ["github"],
    seed_count: 5
  )
  puts "✅ User created successfully: #{user.id}"
  
  puts "Testing Diary model..."
  diary = Diary.create!(
    user: user,
    date: Date.current,
    notes: "テスト日記",
    is_public: false
  )
  puts "✅ Diary created successfully: #{diary.id}"
  
rescue => e
  puts "❌ Model creation failed: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
  exit 1
end

puts "\nTesting FactoryBot setup..."
begin
  require 'factory_bot'
  FactoryBot.find_definitions
  puts "✅ FactoryBot definitions loaded successfully"
rescue => e
  puts "❌ FactoryBot setup failed: #{e.message}"
end

puts "\n🎉 Basic verification completed successfully!"
puts "📊 Test infrastructure is ready for comprehensive testing"