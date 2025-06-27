class AddGithubUploadedToDiaries < ActiveRecord::Migration[7.2]
  def change
    add_column :diaries, :github_uploaded, :boolean
  end
end
