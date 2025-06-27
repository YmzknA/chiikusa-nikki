class AddGithubAuditFieldsToDiaries < ActiveRecord::Migration[7.2]
  def change
    add_column :diaries, :github_uploaded_at, :datetime
    add_column :diaries, :github_file_path, :string
    add_column :diaries, :github_commit_sha, :string
    add_column :diaries, :github_repository_url, :string
    
    # Add index for audit queries
    add_index :diaries, :github_uploaded_at
  end
end