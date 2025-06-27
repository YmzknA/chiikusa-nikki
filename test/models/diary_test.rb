require "test_helper"

class DiaryTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      github_id: "123456789",
      username: "testuser",
      email: "test@example.com",
      encrypted_access_token: "encrypted_token",
      providers: ["github"],
      password: Devise.friendly_token[0, 20]
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
