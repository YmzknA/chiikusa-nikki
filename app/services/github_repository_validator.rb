module GithubRepositoryValidator
  def valid_repository_name?(repo_name)
    return false if basic_name_invalid?(repo_name)
    return false if contains_invalid_patterns?(repo_name)
    return false if reserved_name?(repo_name)

    true
  end

  private

  def basic_name_invalid?(repo_name)
    repo_name.blank? || repo_name.length > 100
  end

  def contains_invalid_patterns?(repo_name)
    repo_name.start_with?(".", "-") ||
      repo_name.end_with?(".", "-") ||
      !repo_name.match?(/\A[a-zA-Z0-9._-]+\z/) ||
      repo_name.include?("..")
  end

  def reserved_name?(repo_name)
    reserved_names = %w[con prn aux nul com1 com2 com3 com4 com5 com6 com7 com8 com9
                        lpt1 lpt2 lpt3 lpt4 lpt5 lpt6 lpt7 lpt8 lpt9]
    problematic_names = %w[. .. git HEAD]

    reserved_names.include?(repo_name.downcase) || problematic_names.include?(repo_name)
  end
end
