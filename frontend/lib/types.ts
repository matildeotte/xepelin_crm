export type Tone = "success" | "warning" | "danger" | "info" | "neutral";

export type LabeledValue = {
  value: string;
  label: string;
  tone?: Tone;
};

export type CompanyMetrics = {
  financed_amount: number;
  sii_volume: number;
  share_of_wallet: number;
  expansion_opportunity: number;
  eligible_expansion_opportunity: number;
  top_debtor_concentration: number;
  last_financed_on: string | null;
};

export type CompanySummary = {
  id: number;
  legal_name: string;
  tax_id: string;
  sector: string;
  created_at: string;
  sii_connected_at: string | null;
  activation_state: LabeledValue;
  next_best_action: LabeledValue;
  latest_risk_eligibility: RiskEligibility | null;
  latest_health_score: HealthScore | null;
  metrics: CompanyMetrics;
};

export type CompanyDetail = CompanySummary & {
  risk_eligibilities: RiskEligibility[];
  financed_invoices: Invoice[];
  opportunity_invoices: (Invoice & { suggested_action: string })[];
  interactions: Interaction[];
};

export type CompanyLink = {
  id: number;
  legal_name: string;
  tax_id: string;
};

export type DebtorLink = {
  id: number;
  legal_name: string;
  tax_id: string;
};

export type Debtor = DebtorLink & {
  sector: string;
  payment_probability: LabeledValue;
  metrics: {
    xepelin_invoice_count: number;
    global_financed_amount: number;
    open_exposure: number;
    on_time_payment_rate: number | null;
  };
};

export type Invoice = {
  id: number;
  invoice_number: string;
  amount: number;
  issue_date: string;
  due_date: string;
  financed_on: string | null;
  paid_on: string | null;
  assigned: boolean;
  assignment_date: string | null;
  moratory_monthly_rate: number;
  days_overdue: number;
  source: LabeledValue;
  status: LabeledValue;
  debtor_response_status: LabeledValue;
  company: CompanyLink | null;
  debtor: DebtorLink | null;
};

export type RiskEligibility = {
  id: number;
  reason: string;
  evaluated_at: string;
  status: LabeledValue;
  risk_type: LabeledValue;
  company: CompanyLink | null;
  debtor: DebtorLink | null;
};

export type Interaction = {
  id: number;
  summary: string;
  created_at: string;
  kind: LabeledValue;
};

export type HealthScore = {
  id: number;
  score: number;
  summary: string;
  recommended_actions: string[];
  created_at: string;
  churn_risk: LabeledValue;
};

export type RiskUnlockedOpportunity = {
  id: number;
  company: CompanyLink;
  debtor: DebtorLink;
  available_amount: number;
  invoice_count: number;
  evaluated_at: string;
  action: string;
  secondary_action: string;
};

export type DashboardResponse = {
  metrics: {
    portfolio_count: number;
    operating_companies_count: number;
    operating_rate: number;
    financed_amount: number;
    monthly_goal_amount: number;
    monthly_goal_progress: number;
    sii_volume: number;
    share_of_wallet: number;
    expansion_opportunity: number;
    eligible_expansion_pipeline: number;
    unpaid_invoices_count: number;
    collection_blocker_amount: number;
    overdue_amount: number;
  };
  top_financed_companies: CompanySummary[];
  risk_unlocked_opportunities: RiskUnlockedOpportunity[];
  unpaid_invoices: Invoice[];
};

export type CompaniesResponse = {
  companies: CompanySummary[];
};

export type CompanyResponse = {
  company: CompanyDetail;
  interaction_kinds: LabeledValue[];
};

export type DebtorResponse = {
  debtor: Debtor;
  portfolio_invoices: Invoice[];
  global_xepelin_invoices: Invoice[];
  risk_eligibilities: RiskEligibility[];
};

export type InvoicesResponse = {
  invoices: Invoice[];
};

export type SessionResponse = {
  user: {
    id: number;
    email: string;
    name: string;
    avatar_url: string | null;
  };
};
