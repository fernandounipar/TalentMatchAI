# Perfis e Permissões

Perfis suportados:
- `USER`: acesso básico aos recursos do próprio tenant.
- `ADMIN`: gestão de usuários/recursos do próprio tenant.
- `SUPER_ADMIN`: visão e suporte global, fora do escopo do tenant (usar com parcimônia).

Rotas administrativas devem usar `exigirRole('ADMIN','SUPER_ADMIN')`. O payload do token deve incluir `role` e `company_id`.
