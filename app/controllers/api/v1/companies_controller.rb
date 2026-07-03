class Api::V1::CompaniesController < Api::V1::BaseController
  def index
    companies = current_user.companies.includes(:invoices, :risk_eligibilities).sort_by do |company|
      [
        company.operating? ? 0 : 1,
        -company.financed_amount(from: current_month.begin, to: current_month.end)
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
