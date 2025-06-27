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

ActiveRecord::Schema[7.2].define(version: 2025_06_27_065311) do
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
    t.boolean "is_public"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "github_uploaded", default: false, null: false
    t.datetime "github_uploaded_at"
    t.string "github_file_path"
    t.string "github_commit_sha"
    t.string "github_repository_url"
    t.index ["github_uploaded"], name: "index_diaries_on_github_uploaded"
    t.index ["github_uploaded_at"], name: "index_diaries_on_github_uploaded_at"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_id"], name: "index_users_on_github_id", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answers", "questions"
  add_foreign_key "diaries", "users"
  add_foreign_key "diary_answers", "answers"
  add_foreign_key "diary_answers", "diaries"
  add_foreign_key "diary_answers", "questions"
  add_foreign_key "til_candidates", "diaries"
end
