class AddConstraintsToGithubUploaded < ActiveRecord::Migration[7.2]
  def up
    # Set default value for existing records
    change_column_default :diaries, :github_uploaded, false
    
    # Update any NULL values to false
    execute "UPDATE diaries SET github_uploaded = false WHERE github_uploaded IS NULL"
    
    # Add NOT NULL constraint
    change_column_null :diaries, :github_uploaded, false
    
    # Add performance indexes
    add_index :diaries, :github_uploaded
    add_index :diaries, [:user_id, :github_uploaded]
  end

  def down
    # Remove indexes
    remove_index :diaries, :github_uploaded
    remove_index :diaries, [:user_id, :github_uploaded]
    
    # Remove NOT NULL constraint
    change_column_null :diaries, :github_uploaded, true
    
    # Remove default value
    change_column_default :diaries, :github_uploaded, nil
  end
end