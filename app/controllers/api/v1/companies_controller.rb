class Api::V1::CompaniesController < Api::V1::BaseController
  def index
    companies = current_user.companies.includes(:health_scores, :invoices, :risk_eligibilities).sort_by do |company|
      [
        company.health_scores.max_by(&:created_at)&.score || 101,
        -eligible_expansion_opportunity(company, from: current_month.begin, to: current_month.end),
        company.risk_eligibilities.company_level.max_by(&:evaluated_at)&.not_eligible? ? 1 : 0
      ]
    end

    render json: { companies: companies.map { |company| serialize_company_summary(company) } }
  end

  def show
    company = current_user.companies.find(params[:id])

    render json: {
      company: serialize_company_detail(company),
      interaction_kinds: Interaction.kinds.keys.map do |kind|
        { value: kind, label: Interaction.human_enum_name(:kind, kind) }
      end
    }
  end
end
