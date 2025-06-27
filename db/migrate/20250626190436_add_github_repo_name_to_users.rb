class AddGithubRepoNameToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :github_repo_name, :string
  end
end
