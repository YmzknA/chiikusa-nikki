class AddGithubUsernameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :github_username, :string
  end
end
