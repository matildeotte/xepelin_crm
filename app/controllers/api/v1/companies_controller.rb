class Api::V1::CompaniesController < Api::V1::BaseController
  def index
    companies = current_user.companies.includes(:health_scores, :invoices, :risk_eligibilities).sort_by do |company|
      latest_risk = company.risk_eligibilities.company_level.max_by(&:evaluated_at)
      latest_score = company.health_scores.max_by(&:created_at)&.score

      [
        -eligible_expansion_opportunity(company, from: current_month.begin, to: current_month.end),
        risk_priority(latest_risk),
        -(latest_score || 0),
        -company.share_of_wallet(from: current_month.begin, to: current_month.end)
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

  private

  def risk_priority(risk_eligibility)
    return 0 if risk_eligibility&.eligible?
    return 1 if risk_eligibility&.in_review?
    return 2 if risk_eligibility&.not_eligible?

    3
  end
end
