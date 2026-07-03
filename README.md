# Xepelin Growth CRM

CRM para priorización comercial de una cartera KAM en Xepelin.

El producto está separado en un backend Rails API y un frontend Next.js + Mantine dentro del mismo repo. El foco es ayudar al KAM a entender:

- Cuántos clientes asignados están operando.
- Cuánto monto se ha financiado.
- Share of Wallet (SOW): monto financiado por Xepelin vs. volumen visible en SII.
- Oportunidades de crecimiento en clientes activos.
- Outputs de elegibilidad entregados por Riesgos.
- Bloqueos de cobranza como contexto para continuidad operacional.

Rails no renderiza vistas ERB para el producto. Solo expone `/api/v1/*`, maneja Google OAuth/logout y redirige `/` al frontend Next.

## Stack

- Ruby `3.2.2`
- Rails `7.2.x`
- PostgreSQL
- Google OAuth via `omniauth-google-oauth2`
- Next.js + Mantine in `frontend/`
- Synthetic data via `faker`

## First-Time Setup Backend

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

## Frontend Setup

Install frontend dependencies:

```bash
cd frontend
npm install
```

Optional local env file:

```bash
cp .env.example .env.local
```

By default, the frontend runs at `http://localhost:3001` and proxies `/api/*` requests to Rails at `http://localhost:3000`.

## Run The App

Start the Rails API:

```bash
FRONTEND_URL=http://localhost:3001 bin/rails s -p 3000
```

Optional monthly goal for the dashboard:

```bash
MONTHLY_FINANCING_GOAL_CLP=300000000
```

Start the Next frontend in another terminal:

```bash
cd frontend
npm run dev
```

Open:

```text
http://localhost:3001
```

Open Rails console:

```bash
bin/rails console
```

## Demo Narrative

The CRM is designed around the real KAM goal: increase operated clients and financed amount.

Key screens:

- Dashboard: SOW, eligible expansion pipeline, operating clients, financed amount vs. goal, risk-unlocked opportunities, and collection blockers.
- Companies: assigned client list prioritized by Health Score AI, SOW, eligible SII opportunity, Risk output, and next best action.
- Company detail: financed invoices, SII-visible invoices not financed by Xepelin, Risk outputs, interactions, and simulation actions.
- Debtor detail: global debtor behavior across Xepelin plus detailed invoices scoped to the logged-in KAM's portfolio.
- Unpaid invoices: operational blockers owned by Collections but visible to KAMs because they may affect future operation.

## API Endpoints

The frontend consumes JSON from Rails under `/api/v1`:

- `GET /api/v1/session`
- `GET /api/v1/dashboard`
- `GET /api/v1/companies`
- `GET /api/v1/companies/:id`
- `POST /api/v1/companies/:company_id/interactions`
- `GET /api/v1/debtors/:id`
- `GET /api/v1/invoices/unpaid`

## Domain Notes

- `Company` is the Xepelin client managed by the KAM.
- `Debtor` is the payer of the invoice.
- `Invoice.source = xepelin` means the invoice was financed by Xepelin.
- `Invoice.source = sii_only` means the invoice was seen through the client's SII scraper but was not financed by Xepelin.
- `RiskEligibility` stores the output from Risk. The CRM consumes it; it does not calculate credit, operational, or fraud risk.
- Collection status is informational for the KAM. Collections owns recovery, but overdue invoices can block the client from continuing to operate.
