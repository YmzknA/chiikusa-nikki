require "test_helper"

class DiariesControllerTest < ActionController::TestCase
  setup do
    # Create a test user
    @user = User.create!(
      username: "testuser",
      email: "test@example.com",
      password: "password123"
    )
    
    # Create test questions and answers
    @mood_question = Question.create!(identifier: "mood", label: "今日の気分")
    @motivation_question = Question.create!(identifier: "motivation", label: "学習のモチベーション")
    
    @mood_happy = Answer.create!(question: @mood_question, level: 4, emoji: "😄")
    @motivation_high = Answer.create!(question: @motivation_question, level: 5, emoji: "💥")
    
    # Sign in the user
    sign_in @user
  end

  test "should create diary with mood answers" do
    assert_difference('Diary.count') do
      assert_difference('DiaryAnswer.count', 2) do
        post :create, params: {
          diary: {
            date: Date.current,
            notes: "Today I learned Ruby on Rails",
            is_public: false
          },
          diary_answers: {
            mood: @mood_happy.id,
            motivation: @motivation_high.id
          }
        }
      end
    end
    
    diary = Diary.last
    assert_equal 2, diary.diary_answers.count
    
    mood_answer = diary.diary_answers.find_by(question: @mood_question)
    assert_equal @mood_happy, mood_answer.answer
    
    motivation_answer = diary.diary_answers.find_by(question: @motivation_question)
    assert_equal @motivation_high, motivation_answer.answer
  end

  test "should handle missing diary_answers gracefully" do
    assert_difference('Diary.count') do
      assert_no_difference('DiaryAnswer.count') do
        post :create, params: {
          diary: {
            date: Date.current,
            notes: "Today I learned Ruby on Rails",
            is_public: false
          }
        }
      end
    end
  end
end