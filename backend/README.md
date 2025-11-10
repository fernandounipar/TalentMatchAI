Backend TalentMatchIA

Quick start

- Copy `backend/.env.example` to `backend/.env` and adjust:
  - `DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME`
  - `JWT_SECRET`
  - `CORS_ORIGIN` (ex.: http://localhost:5173 or flutter web port)
  - Optional: `OPENAI_API_KEY`
- Install deps and apply DB migrations:
  - `cd backend`
  - `npm install`
  - `npm run db:apply`
- Start API:
  - `npm run dev` or `npm start`

Important

- Auth returns `access_token` (JWT with id, companyId, perfil) and a rotating `refresh_token`.
- Send `Authorization: Bearer <access_token>` on requests. On 401, call `POST /api/auth/refresh` with the refresh token to obtain a new access and refresh.
- All queries are tenant-scoped by `company_id`, extracted from the JWT. Optional RLS policies are created by migrations; enable per-table if desired.

Main endpoints

- `POST /api/auth/registrar` — Register company + first user
- `POST /api/auth/login` — Login
- `POST /api/auth/refresh` — Rotate refresh token
- `POST /api/auth/logout` — Revoke session tokens
- `POST /api/auth/forgot-password` → `POST /api/auth/reset-password`
- `GET/POST/PUT/DELETE /api/vagas` — Jobs for the tenant
- `GET /api/candidatos` — Candidates list
- `POST /api/curriculos/upload` — Upload resume (PDF/TXT/DOCX)
- `GET/POST /api/entrevistas/:id/(mensagens|chat|perguntas|relatorio)`

Requests samples are in `backend/requests.http`.

