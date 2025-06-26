# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Questions and Answers
questions = [
  { identifier: "mood", label: "今日の気分", icon: "" },
  { identifier: "motivation", label: "学習のモチベーション", icon: "" },
  { identifier: "progress", label: "学習の進捗", icon: "" }
]

answers = {
  mood: [
    { level: 1, label: "", emoji: "😞" },
    { level: 2, label: "", emoji: "😐" },
    { level: 3, label: "", emoji: "🙂" },
    { level: 4, label: "", emoji: "😄" },
    { level: 5, label: "", emoji: "😁" }
  ],
  motivation: [
    { level: 1, label: "", emoji: "🧊" },
    { level: 2, label: "", emoji: "💧" },
    { level: 3, label: "", emoji: "🔥" },
    { level: 4, label: "", emoji: "☄️" },
    { level: 5, label: "", emoji: "💥" }
  ],
  progress: [
    { level: 1, label: "", emoji: "🪹" },
    { level: 2, label: "", emoji: "🌰" },
    { level: 3, label: "", emoji: "🌱" },
    { level: 4, label: "", emoji: "🌿" },
    { level: 5, label: "", emoji: "🌳" }
  ]
}

questions.each do |q_data|
  question = Question.find_or_create_by!(identifier: q_data[:identifier]) do |q|
    q.label = q_data[:label]
    q.icon = q_data[:icon]
  end

  answers[q_data[:identifier].to_sym].each do |a_data|
    question.answers.find_or_create_by!(level: a_data[:level]) do |a|
      a.label = a_data[:label]
      a.emoji = a_data[:emoji]
    end
  end
end