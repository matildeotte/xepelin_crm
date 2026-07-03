# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

class GeminiApi
  MissingCredentialsError = Class.new(StandardError)

  TEXT_MODELS = %w[
    gemini-2.5-flash
    gemini-2.0-flash
    gemini-2.0-flash-lite
    gemini-2.5-flash-lite
    gemini-2.0-flash-001
  ].freeze

  def initialize(api_key: nil, base_url: nil, models: TEXT_MODELS)
    @api_key = api_key.presence || Rails.application.credentials.dig(:gemini, :api_key)
    @base_url = base_url.presence || Rails.application.credentials.dig(:gemini, :base_url)
    @models = models

    raise MissingCredentialsError, "Missing credentials.gemini.api_key" if @api_key.blank?
    raise MissingCredentialsError, "Missing credentials.gemini.base_url" if @base_url.blank?
  end

  def generate_json(contents:, schema:, temperature: 0.2)
    last_response = nil

    @models.each do |model|
      response = json_post(
        URI("#{@base_url}#{model}:generateContent?key=#{@api_key}"),
        json_payload(contents:, schema:, temperature:)
      )
      last_response = response

      return parsed_success(response) if response.code.to_i == 200

      Rails.logger.warn("[GeminiApi] #{model} failed with HTTP #{response.code}: #{response.body}")
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.warn("[GeminiApi] #{model} timed out: #{e.message}")
      next
    rescue StandardError => e
      Rails.logger.warn("[GeminiApi] #{model} failed unexpectedly: #{e.message}")
      next
    end

    handle_failure(last_response)
  end

  private

  def json_payload(contents:, schema:, temperature:)
    {
      contents: contents,
      generationConfig: {
        temperature: temperature,
        responseMimeType: "application/json",
        responseSchema: schema
      }
    }
  end

  def parsed_success(response)
    body = JSON.parse(response.body)

    {
      text: extract_text(body),
      usage: body["usageMetadata"] || {},
      full_body: body
    }
  end

  def extract_text(body)
    parts = body.dig("candidates", 0, "content", "parts")
    return parts.filter_map { |part| part["text"] }.join if parts.is_a?(Array)

    body.dig("candidates", 0, "content", "parts", 0, "text").to_s
  end

  def handle_failure(response)
    payload =
      if response
        parse_json_or_string(response.body).merge("last_http_code" => response.code)
      else
        { "error" => "network_error" }
      end

    raise StandardError, "Gemini API failed: #{payload.inspect}"
  end

  def parse_json_or_string(body)
    parsed = JSON.parse(body)
    parsed.is_a?(Hash) ? parsed : { "response" => parsed }
  rescue JSON::ParserError
    { "response" => body.to_s }
  end

  def json_post(uri, payload)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    http.request(request)
  end
end
