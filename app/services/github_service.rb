require "octokit"

class GithubService
  def initialize(user)
    @user = user
    @client = Octokit::Client.new(access_token: @user.access_token)
  end

  def push_til(diary)
    repo_name = "#{@user.username}/til"
    file_path = "#{diary.date.strftime('%y%m%d')}_til.md"
    content = diary.til_text

    begin
      @client.create_contents(repo_name, file_path, "Add TIL for #{diary.date}", content)
    rescue Octokit::NotFound
      @client.create_repository("til", private: true)
      @client.create_contents(repo_name, file_path, "Add TIL for #{diary.date}", content)
    end
  end
end
