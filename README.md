# Xepelin Growth CRM

CRM para priorización comercial de una cartera KAM en Xepelin.

El producto está separado en un backend Rails API y un frontend Next.js + Mantine dentro del mismo repositorio. El foco es ayudar al KAM a entender:

- Cuántos clientes asignados están operando.
- Cuánto monto se ha financiado.
- Share of Wallet (SOW): monto financiado por Xepelin vs. volumen visible en SII.
- Oportunidades de crecimiento en clientes activos.
- Resultados de elegibilidad entregados por Riesgos.
- Bloqueos de cobranza como contexto para continuidad operacional.

Rails no renderiza vistas ERB para el producto. Solo expone `/api/v1/*`, maneja Google OAuth/logout y redirige `/` al frontend Next.

## Stack

- Ruby `3.2.2`
- Rails `7.2.x`
- PostgreSQL
- Google OAuth con `omniauth-google-oauth2`
- Next.js + Mantine en `frontend/`
- Datos sintéticos con `faker`

## Configuración inicial del backend

Desde la carpeta del proyecto:

```bash
bundle install
```

## Base de datos

Crear y migrar la base de datos:

```bash
bin/rails db:create
bin/rails db:migrate
```

Cargar datos de demo y asignar la cartera principal al mismo email que usarás con Google:

```bash
DEMO_USER_EMAIL=tu_email@gmail.com bin/rails db:seed
```

Esto importa porque el dashboard solo muestra empresas asignadas al KAM logueado. Si haces seed con otro email, la app puede autenticarte bien pero mostrar una cartera vacía.

## Health Scores con Gemini

La app usa generación de texto con Gemini para persistir un `HealthScore` por empresa:

- `health_score`: número entre `0` y `100`.
- `churn_risk`: `low`, `medium` o `high`.
- `summary`: explicación breve para el KAM.
- `recommended_actions`: acciones comerciales concretas.

Generar scores:

```bash
LIMIT=5 bin/rails health_scores:generate
```

Opciones útiles: `COMPANY_ID`, `USER_EMAIL`, `FORCE=true`, `SLEEP_SECONDS`.

## Configuración del frontend

Instalar dependencias:

```bash
cd frontend
npm install
```

Por defecto, el frontend corre en `http://localhost:3001` y hace proxy de las peticiones `/api/*` hacia Rails en `http://localhost:3000`.

## Levantar la app

Iniciar la API Rails:

```bash
FRONTEND_URL=http://localhost:3001 bin/rails s -p 3000
```

Meta mensual opcional para el dashboard:

```bash
MONTHLY_FINANCING_GOAL_CLP=300000000
```

Iniciar el frontend Next en otra terminal:

```bash
cd frontend
npm run dev
```

Abrir:

```text
http://localhost:3001
```
