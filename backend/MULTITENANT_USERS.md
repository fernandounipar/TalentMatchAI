# Usuários Multi-Tenant

Este projeto usa isolamento lógico por `company_id` em um único banco. Cada `user` pertence a uma `company` e todas as consultas devem ser filtradas por `company_id`.

Pontos-chave:
- `users(company_id, email)` é único por tenant.
- JWT carrega `sub` (user id), `company_id` e `role` (`USER`, `ADMIN`, `SUPER_ADMIN`).
- Use guards de autorização para restringir ações sensíveis.
- (Opcional) RLS no PostgreSQL adiciona uma segunda barreira: defina `set_config('app.tenant_id','<uuid>', true)` por sessão.

Tabelas relacionadas: `sessions`, `refresh_tokens`, `password_resets`, `audit_logs`.
