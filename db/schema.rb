# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_06_221250) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.integer "level"
    t.string "label"
    t.string "emoji"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "daily_weathers", force: :cascade do |t|
    t.date "date"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_weathers_on_date", unique: true
  end

  create_table "diaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date"
    t.text "notes"
    t.text "til_text"
    t.integer "selected_til_index"
    t.boolean "is_public", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "github_uploaded", default: false, null: false
    t.datetime "github_uploaded_at"
    t.string "github_file_path"
    t.string "github_commit_sha"
    t.string "github_repository_url"
    t.index ["github_uploaded"], name: "index_diaries_on_github_uploaded"
    t.index ["github_uploaded_at"], name: "index_diaries_on_github_uploaded_at"
    t.index ["is_public", "date"], name: "index_diaries_on_is_public_and_date"
    t.index ["is_public"], name: "index_diaries_on_is_public"
    t.index ["user_id", "date"], name: "index_diaries_on_user_id_and_date", unique: true
    t.index ["user_id", "github_uploaded"], name: "index_diaries_on_user_id_and_github_uploaded"
    t.index ["user_id"], name: "index_diaries_on_user_id"
  end

  create_table "diary_answers", force: :cascade do |t|
    t.bigint "diary_id", null: false
    t.bigint "question_id", null: false
    t.bigint "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_diary_answers_on_answer_id"
    t.index ["diary_id"], name: "index_diary_answers_on_diary_id"
    t.index ["question_id"], name: "index_diary_answers_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.string "identifier"
    t.string "label"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "diary_id", null: false
    t.string "emoji", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["diary_id", "emoji"], name: "index_reactions_on_diary_emoji"
    t.index ["diary_id", "emoji"], name: "index_reactions_on_diary_id_and_emoji"
    t.index ["diary_id", "user_id", "emoji"], name: "index_reactions_unique_constraint", unique: true
    t.index ["diary_id"], name: "index_reactions_on_diary_id"
    t.index ["user_id", "diary_id", "emoji"], name: "index_reactions_on_user_id_and_diary_id_and_emoji", unique: true
    t.index ["user_id", "diary_id"], name: "index_reactions_on_user_diary"
    t.index ["user_id"], name: "index_reactions_on_user_id"
  end

  create_table "til_candidates", force: :cascade do |t|
    t.bigint "diary_id", null: false
    t.text "content"
    t.integer "index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["diary_id"], name: "index_til_candidates_on_diary_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "github_id"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "github_repo_name"
    t.text "encrypted_access_token"
    t.string "google_id"
    t.string "google_email"
    t.string "encrypted_google_access_token"
    t.text "providers"
    t.integer "seed_count", default: 0, null: false
    t.datetime "last_seed_incremented_at"
    t.datetime "last_shared_at"
    t.string "github_username"
    t.index ["email"], name: "index_users_on_email"
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
    t.index ["google_email"], name: "index_users_on_google_email"
    t.index ["google_id"], name: "index_users_on_google_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "diaries", "users"
  add_foreign_key "diary_answers", "answers"
  add_foreign_key "diary_answers", "diaries"
  add_foreign_key "diary_answers", "questions"
  add_foreign_key "reactions", "diaries"
  add_foreign_key "reactions", "users"
  add_foreign_key "til_candidates", "diaries"
end
