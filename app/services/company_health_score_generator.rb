# frozen_string_literal: true

class CompanyHealthScoreGenerator
  InvalidResponseError = Class.new(StandardError)

  RESPONSE_SCHEMA = {
    type: "OBJECT",
    properties: {
      health_score: { type: "INTEGER" },
      churn_risk: { type: "STRING", enum: %w[low medium high] },
      summary: { type: "STRING" },
      recommended_actions: {
        type: "ARRAY",
        items: { type: "STRING" }
      }
    },
    required: %w[health_score churn_risk summary recommended_actions]
  }.freeze

  def initialize(company, api: GeminiApi.new)
    @company = company
    @api = api
  end

  def call!
    result = api.generate_json(
      contents: CompanyHealthScorePrompt.new(company).contents,
      schema: RESPONSE_SCHEMA,
      temperature: 0.2
    )
    payload = normalize_payload(parse_payload(result[:text]))

    company.health_scores.create!(
      score: payload.fetch("health_score"),
      churn_risk: payload.fetch("churn_risk"),
      summary: payload.fetch("summary"),
      recommended_actions: payload.fetch("recommended_actions")
    )
  end

  private

  attr_reader :company, :api

  def parse_payload(text)
    JSON.parse(text)
  rescue JSON::ParserError
    JSON.parse(extract_json_object(text))
  rescue TypeError
    raise InvalidResponseError, "Gemini returned an empty response"
  end

  def extract_json_object(text)
    match = text.to_s.match(/\{.*\}/m)
    raise InvalidResponseError, "Gemini response did not include a JSON object: #{text.inspect}" unless match

    match[0]
  end

  def normalize_payload(payload)
    raise InvalidResponseError, "Gemini response must be a JSON object" unless payload.is_a?(Hash)

    score = Integer(payload["health_score"])
    raise InvalidResponseError, "health_score must be between 0 and 100" unless score.between?(0, 100)

    churn_risk = payload["churn_risk"].to_s
    raise InvalidResponseError, "Invalid churn_risk: #{churn_risk}" unless HealthScore.churn_risks.key?(churn_risk)

    summary = payload["summary"].to_s.strip
    raise InvalidResponseError, "summary cannot be blank" if summary.blank?

    recommended_actions = Array(payload["recommended_actions"]).map { |action| action.to_s.strip }.reject(&:blank?)
    raise InvalidResponseError, "recommended_actions must include at least one action" if recommended_actions.empty?

    {
      "health_score" => score,
      "churn_risk" => churn_risk,
      "summary" => summary,
      "recommended_actions" => recommended_actions.first(5)
    }
  rescue ArgumentError, TypeError => e
    raise InvalidResponseError, "Invalid Gemini payload: #{e.message}"
  end
end
