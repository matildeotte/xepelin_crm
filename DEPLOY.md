# Deploy en Render

Guía paso a paso para desplegar el monorepo (Rails API + Next.js + PostgreSQL).

## Arquitectura

| Servicio | Qué es | URL ejemplo |
|---|---|---|
| PostgreSQL | Base de datos | *(interna, no pública)* |
| `xepelin-crm-api` | Rails API + OAuth | `https://xepelin-crm-api.onrender.com` |
| `xepelin-crm-web` | Next.js frontend | `https://xepelin-crm-web.onrender.com` |

La URL que compartes con evaluadores es la del **frontend**.

---

## Paso 0 — Preparar el repo en GitHub

Antes de deployar, asegúrate de haber pusheado:

- `config/master.key` **fuera** del repo (en `.gitignore`)
- Los cambios de deploy (CORS, `database.yml`, etc.)

```bash
git add .
git commit -m "Preparar deploy en Render"
git push origin main
```

Genera un `SECRET_KEY_BASE` para producción (guárdalo, lo usarás en Render):

```bash
bin/rails secret
```

Copia también el contenido de `config/master.key` (para `RAILS_MASTER_KEY`).

---

## Paso 1 — Crear la base de datos PostgreSQL

1. Entra a [render.com](https://render.com) y crea cuenta (puedes usar GitHub).
2. **New +** → **PostgreSQL**.
3. Name: `xepelin-crm-db`
4. Region: la más cercana (ej. Oregon).
5. Plan: **Free**.
6. **Create Database**.
7. En la pestaña **Info**, copia la **Internal Database URL** (empieza con `postgresql://`).

---

## Paso 2 — Crear el backend Rails

1. **New +** → **Web Service**.
2. Conecta tu repositorio de GitHub.
3. Configura:

| Campo | Valor |
|---|---|
| Name | `xepelin-crm-api` |
| Region | La misma que la DB |
| Branch | `main` |
| Root Directory | *(dejar vacío)* |
| Runtime | **Ruby** |
| Build Command | `./bin/render-build.sh` |
| Start Command | `bundle exec puma -C config/puma.rb` |
| Plan | **Free** |

4. En **Environment Variables**, agrega:

| Key | Value |
|---|---|
| `RAILS_ENV` | `production` |
| `RAILS_MASTER_KEY` | contenido de tu `config/master.key` |
| `SECRET_KEY_BASE` | output de `bin/rails secret` |
| `DATABASE_URL` | Internal Database URL del paso 1 |
| `FRONTEND_URL` | `https://xepelin-crm-web.onrender.com` *(ajusta si usas otro nombre)* |
| `RAILS_PUBLIC_URL` | `https://xepelin-crm-api.onrender.com` |
| `RAILS_LOG_LEVEL` | `info` |

5. **Create Web Service** y espera el deploy.

6. Anota la URL pública del API, ej. `https://xepelin-crm-api.onrender.com`.

7. Prueba health check: `https://xepelin-crm-api.onrender.com/up` → debe responder `200`.

---

## Paso 3 — Crear el frontend Next.js

1. **New +** → **Web Service**.
2. Mismo repositorio de GitHub.
3. Configura:

| Campo | Valor |
|---|---|
| Name | `xepelin-crm-web` |
| Region | La misma |
| Branch | `main` |
| Root Directory | `frontend` |
| Runtime | **Node** |
| Build Command | `npm install && npm run build` |
| Start Command | `npm run start` |
| Plan | **Free** |

4. **Environment Variables**:

| Key | Value |
|---|---|
| `RAILS_API_BASE_URL` | `https://xepelin-crm-api.onrender.com` |
| `NEXT_PUBLIC_AUTH_BASE_URL` | `https://xepelin-crm-api.onrender.com` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://xepelin-crm-api.onrender.com` |

> Usa la URL real de tu API del paso 2.

5. **Create Web Service** y espera el deploy.

6. Anota la URL del frontend, ej. `https://xepelin-crm-web.onrender.com`.

---

## Paso 4 — Ajustar FRONTEND_URL en Rails

Si la URL real del frontend difiere de la que pusiste en el paso 2:

1. Ve al servicio `xepelin-crm-api` en Render.
2. **Environment** → edita `FRONTEND_URL` con la URL exacta del frontend.
3. Guarda → Render redeployea solo.

---

## Paso 5 — Configurar Google OAuth

En [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials** → tu OAuth 2.0 Client:

**Authorized JavaScript origins:**
```
https://xepelin-crm-web.onrender.com
https://xepelin-crm-api.onrender.com
```

**Authorized redirect URIs:**
```
https://xepelin-crm-api.onrender.com/auth/google_oauth2/callback
```

Guarda los cambios (pueden tardar unos minutos en aplicar).

---

## Paso 6 — Cargar datos de demo

1. En Render, abre el servicio `xepelin-crm-api`.
2. Pestaña **Shell** (solo disponible en plan de pago) **o** usa **Manual Deploy** con un one-off job.

Si no tienes Shell en free tier, corre el seed localmente apuntando a la DB de Render (más complejo) o sube temporalmente a un plan con Shell.

**Alternativa en free tier:** agrega al Build Command temporalmente:

```bash
./bin/render-build.sh && DEMO_USER_EMAIL=tu@gmail.com bundle exec rails db:seed
```

Solo la primera vez; luego quita el seed del build command.

Para Health Scores (opcional):

```bash
LIMIT=10 bundle exec rails health_scores:generate
```

Usa el mismo email que usarás para login con Google.

---

## Paso 7 — Probar

1. Abre `https://xepelin-crm-web.onrender.com`
2. Click en **Iniciar sesión con Google**
3. Deberías volver al dashboard con empresas de tu cartera

Si falla el login:
- Revisa redirect URI en Google Console
- Revisa que `RAILS_PUBLIC_URL` y `FRONTEND_URL` estén correctos
- Revisa logs del servicio API en Render

---

## Variables de entorno — resumen

### Rails (`xepelin-crm-api`)

```
RAILS_ENV=production
RAILS_MASTER_KEY=...
SECRET_KEY_BASE=...
DATABASE_URL=postgresql://...
FRONTEND_URL=https://xepelin-crm-web.onrender.com
RAILS_PUBLIC_URL=https://xepelin-crm-api.onrender.com
```

### Next.js (`xepelin-crm-web`)

```
RAILS_API_BASE_URL=https://xepelin-crm-api.onrender.com
NEXT_PUBLIC_AUTH_BASE_URL=https://xepelin-crm-api.onrender.com
NEXT_PUBLIC_API_BASE_URL=https://xepelin-crm-api.onrender.com
```

---

## Tips

- **Free tier:** los servicios se duermen tras ~15 min sin uso. La primera carga puede tardar ~1 min.
- **Logs:** Render → tu servicio → **Logs** para debug.
- **master.key:** nunca la subas al repo; usa `RAILS_MASTER_KEY` en Render.
- Si cambias credentials localmente, redeployea el API (el `.enc` sí va en git).
