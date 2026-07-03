# Xepelin Growth CRM

Rails CRM prototype for a KAM portfolio at Xepelin.

The app is focused on Growth and commercial execution, not collections or risk modeling. KAMs use it to understand:

- How many assigned clients are currently operating.
- How much amount has been financed.
- Share of Wallet (SOW): financed amount through Xepelin vs. total invoice volume visible through SII.
- Expansion and reactivation opportunities.
- Risk team eligibility outputs that Commercial consumes before pitching new operations.
- Collection blockers that may prevent a client from continuing to operate.

## Stack

- Ruby `3.2.2`
- Rails `7.2.x`
- PostgreSQL
- Google OAuth via `omniauth-google-oauth2`
- Synthetic data via `faker`

## First-Time Setup

From the project folder:

```bash
bundle install
```

## Database Setup

Create and migrate the database:

```bash
bin/rails db:create
bin/rails db:migrate
```

Load demo data and assign the main KAM portfolio to the same email you will use with Google login:

```bash
DEMO_USER_EMAIL=matildeotte@gmail.com bin/rails db:seed
```

This matters because the dashboard only shows companies assigned to the logged-in KAM. If you seed with a different email, the app may log you in correctly but show an empty portfolio.

## Run The App

Start the Rails server:

```bash
bin/rails s
```

Open:

```text
http://localhost:3000
```

Open Rails console:

```bash
bin/rails console
```

## Demo Narrative

The CRM is designed around the real KAM goal: increase operated clients and financed amount.

Key screens:

- Dashboard: operating clients, financed amount, SOW, expansion opportunity, reactivation opportunities, and collection blockers.
- Companies: assigned client list with activation state, SOW, Risk output, and next best action.
- Company detail: financed invoices, SII-visible invoices not financed by Xepelin, pricing by debtor relationship, Risk outputs, notes, and interactions.
- Debtor detail: global debtor behavior across Xepelin plus detailed invoices scoped to the logged-in KAM's portfolio.
- Unpaid invoices: operational blockers owned by Collections but visible to KAMs because they may affect future operation.

## Domain Notes

- `Company` is the Xepelin client managed by the KAM.
- `Debtor` is the payer of the invoice.
- `Invoice.source = xepelin` means the invoice was financed by Xepelin.
- `Invoice.source = sii_only` means the invoice was seen through the client's SII scraper but was not financed by Xepelin.
- `PricingAgreement` stores the financing rate at the company-debtor relationship level.
- `RiskEligibility` stores the output from Risk. The CRM consumes it; it does not calculate credit, operational, or fraud risk.
- Collection status is informational for the KAM. Collections owns recovery, but overdue invoices can block the client from continuing to operate.
