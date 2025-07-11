require "test_helper"

class DiaryUniquenessTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      github_id: "123456789",
      username: "testuser",
      email: "test@example.com",
      encrypted_access_token: "encrypted_token",
      providers: ["github"],
      password: Devise.friendly_token[0, 20]
    )
  end

  test "should allow one diary per user per date" do
    date = Date.current

    # 最初の日記は作成できる
    diary1 = @user.diaries.build(date: date, notes: "First diary")
    assert diary1.save, "First diary should be created successfully"

    # 同じ日付の日記は作成できない
    diary2 = @user.diaries.build(date: date, notes: "Second diary")
    assert_not diary2.save, "Second diary with same date should not be created"
    assert_includes diary2.errors[:date], "の日記は既に作成されています"
  end

  test "should allow different users to create diaries on same date" do
    user2 = User.create!(
      google_id: "987654321",
      username: "testuser2",
      email: "test2@example.com",
      google_email: "test2@example.com",
      encrypted_google_access_token: "encrypted_token_2",
      providers: ["google_oauth2"],
      password: Devise.friendly_token[0, 20]
    )

    date = Date.current

    # ユーザー1の日記
    diary1 = @user.diaries.build(date: date, notes: "User 1 diary")
    assert diary1.save, "User 1 diary should be created"

    # ユーザー2の同じ日付の日記（これは作成できる）
    diary2 = user2.diaries.build(date: date, notes: "User 2 diary")
    assert diary2.save, "User 2 diary with same date should be created"
  end

  test "should allow same user to create diaries on different dates" do
    # 今日の日記
    diary1 = @user.diaries.build(date: Date.current, notes: "Today's diary")
    assert diary1.save, "Today's diary should be created"

    # 昨日の日記
    diary2 = @user.diaries.build(date: Date.current - 1.day, notes: "Yesterday's diary")
    assert diary2.save, "Yesterday's diary should be created"
  end
end
