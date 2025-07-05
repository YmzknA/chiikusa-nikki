class SeedManager
  def initialize(user)
    @user = user
  end

  def sufficient_seeds?
    @user.seed_count.positive?
  end

  def consume_seed!
    return false unless sufficient_seeds?

    @user.decrement!(:seed_count)
    true
  end

  def current_count
    @user.seed_count
  end

  def insufficient_seeds_message
    "タネが不足しているためTILは生成されませんでした"
  end
end
