# Banco de Dados

Defina `DB_NAME=talentmatch` no arquivo `backend/.env`.

Execução de migrações:
- `npm run db:apply` — aplica todas as migrações em `scripts/sql`.
- `node scripts/apply_single_migration.js <arquivo.sql>` — aplica uma migração específica.
