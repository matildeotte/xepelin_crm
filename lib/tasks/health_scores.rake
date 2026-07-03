# frozen_string_literal: true

namespace :health_scores do
  desc "Generate Gemini health scores for companies"
  task generate: :environment do
    scope = Company.includes(:user, :health_scores, :invoices, :risk_eligibilities, :interactions)
    scope = scope.where(id: ENV["COMPANY_ID"]) if ENV["COMPANY_ID"].present?
    scope = scope.joins(:user).where(users: { email: ENV["USER_EMAIL"] }) if ENV["USER_EMAIL"].present?
    scope = scope.limit(ENV["LIMIT"].to_i) if ENV["LIMIT"].present?

    force = ActiveModel::Type::Boolean.new.cast(ENV.fetch("FORCE", false))
    sleep_seconds = ENV.fetch("SLEEP_SECONDS", "1").to_f
    companies = scope.to_a

    abort "No companies found for the provided filters." if companies.empty?

    puts "Generating Gemini health scores for #{companies.size} companies..."
    puts "Skipping companies with existing health scores. Use FORCE=true to regenerate." unless force

    api =
      begin
        GeminiApi.new
      rescue GeminiApi::MissingCredentialsError => e
        abort "#{e.message}. Add gemini.api_key and gemini.base_url to Rails credentials."
      end

    successes = 0
    failures = 0

    companies.each_with_index do |company, index|
      if company.health_scores.exists? && !force
        puts "[#{index + 1}/#{companies.size}] Skipped #{company.legal_name}: already has a health score"
        next
      end

      print "[#{index + 1}/#{companies.size}] #{company.legal_name}... "
      health_score = CompanyHealthScoreGenerator.new(company, api: api).call!
      successes += 1
      puts "score=#{health_score.score}, churn_risk=#{health_score.churn_risk}"

      sleep sleep_seconds if sleep_seconds.positive? && index < companies.size - 1
    rescue StandardError => e
      failures += 1
      Rails.logger.error("[health_scores:generate] #{company.id} #{company.legal_name}: #{e.class} #{e.message}")
      puts "failed: #{e.message}"
    end

    puts "Done. successes=#{successes}, failures=#{failures}, skipped=#{companies.size - successes - failures}"
  end
end
