require "test_helper"

class DiaryTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      username: "testuser", 
      email: "test@example.com",
      password: "password123"
    )
    
    @mood_question = Question.create!(identifier: "mood", label: "今日の気分")
    @mood_answer = Answer.create!(question: @mood_question, level: 4, emoji: "😄")
  end

  test "should create diary with diary answers" do
    diary = @user.diaries.create!(
      date: Date.current,
      notes: "Test notes",
      is_public: false
    )
    
    diary_answer = diary.diary_answers.create!(
      question: @mood_question,
      answer: @mood_answer
    )
    
    assert_equal 1, diary.diary_answers.count
    assert_equal @mood_question, diary_answer.question
    assert_equal @mood_answer, diary_answer.answer
  end
end
