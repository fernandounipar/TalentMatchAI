# TalentMatchAI - Guia de Setup e Desenvolvimento

## 📋 Status do Projeto

### ✅ Implementado
- ✅ Validação de CPF/CNPJ com dígito verificador
- ✅ Middleware de autenticação JWT melhorado
- ✅ Middleware de tenant isolation (multi-tenant)
- ✅ Serviço completo de autenticação com refresh token rotation
- ✅ Endpoints de auth: register, login, refresh, logout, forgot/reset password
- ✅ Configuração de ambiente (.env.example)
- ✅ Correções de erros de compilação do Flutter

### 🚧 Em Progresso / Pendente
- ⏳ Endpoints CRUD completos (jobs, candidates, applications, interviews, resumes)
- ⏳ Upload de arquivos e parse de currículos
- ⏳ Remoção completa de mocks do frontend
- ⏳ Guards de rota no Flutter
- ⏳ Tela de registro/cadastro
- ⏳ Storage seguro de tokens no frontend
- ⏳ Rate limiting e segurança (helmet)
- ⏳ Auditoria completa
- ⏳ Documentação de API (requests.http)
- ⏳ Testes e2e

---

## 🚀 Setup Local

### Pré-requisitos
- **Node.js** 16+ e npm
- **PostgreSQL** 12+
- **Flutter** 3.2+ (para frontend)
- **Git**

### Backend

1. **Clone e navegue até o backend**
```powershell
cd backend
```

2. **Instale dependências**
```powershell
npm install
```

3. **Configure variáveis de ambiente**
```powershell
# Copie o arquivo de exemplo
copy .env.example .env

# Edite o .env com suas configurações
# Especialmente: DB_PASSWORD, JWT_SECRET, DB_NAME
```

4. **Crie o banco de dados**
```powershell
# No PostgreSQL, crie o banco:
# CREATE DATABASE talentmatch;
```

5. **Execute as migrações**
```powershell
npm run db:apply
```

6. **Inicie o servidor**
```powershell
# Desenvolvimento (com nodemon)
npm run dev

# Produção
npm start
```

O backend estará rodando em `http://localhost:4000`

### Frontend

1. **Navegue até o frontend**
```powershell
cd frontend
```

2. **Instale dependências**
```powershell
flutter pub get
```

3. **Configure variáveis de ambiente**
```powershell
# Copie o arquivo de exemplo
copy .env.example .env

# Edite se necessário (padrão: http://localhost:4000)
```

4. **Execute o app**
```powershell
# Web
flutter run -d chrome

# Ou especifique o device
flutter devices
flutter run -d <device_id>
```

O frontend estará em `http://localhost:8080` (ou porta aleatória do Flutter)

---

## 📡 API Endpoints

### Autenticação

#### POST `/api/auth/register`
Registra nova empresa + primeiro usuário

**Body:**
```json
{
  "type": "CPF",
  "document": "12345678901",
  "name": "João Silva",
  "user": {
    "full_name": "João Silva",
    "email": "joao@example.com",
    "password": "senha123"
  }
}
```

**Response 201:**
```json
{
  "company": {
    "id": "uuid",
    "type": "CPF",
    "document": "12345678901",
    "name": "João Silva"
  },
  "usuario": {
    "id": "uuid",
    "company_id": "uuid",
    "nome": "João Silva",
    "email": "joao@example.com",
    "perfil": "ADMIN"
  },
  "access_token": "eyJ...",
  "refresh_token": "hex..."
}
```

#### POST `/api/auth/login`
Login com email e senha

**Body:**
```json
{
  "email": "joao@example.com",
  "senha": "senha123"
}
```

**Response 200:**
```json
{
  "usuario": {
    "id": "uuid",
    "company_id": "uuid",
    "nome": "João Silva",
    "email": "joao@example.com",
    "perfil": "ADMIN",
    "company_name": "João Silva"
  },
  "access_token": "eyJ...",
  "refresh_token": "hex..."
}
```

#### POST `/api/auth/refresh`
Renova access token (rotaciona refresh token)

**Body:**
```json
{
  "refresh_token": "hex..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "new_hex..."
}
```

#### POST `/api/auth/logout`
Revoga refresh token

**Body:**
```json
{
  "refresh_token": "hex..."
}
```

#### POST `/api/auth/forgot-password`
Solicita reset de senha

**Body:**
```json
{
  "email": "joao@example.com"
}
```

#### POST `/api/auth/reset-password`
Reseta senha com token

**Body:**
```json
{
  "reset_token": "hex...",
  "nova_senha": "novasenha123"
}
```

#### POST `/api/auth/change-password`
Troca senha (usuário logado)

**Headers:** `Authorization: Bearer <access_token>`

**Body:**
```json
{
  "senha_atual": "senha123",
  "nova_senha": "novasenha123"
}
```

#### GET `/api/auth/me`
Retorna dados do usuário autenticado

**Headers:** `Authorization: Bearer <access_token>`

---

## 🔐 Autenticação e Segurança

### JWT Tokens
- **Access Token**: Válido por 15 minutos (curto para segurança)
- **Refresh Token**: Válido por 7 dias, armazenado no banco, rotacionado a cada uso
- **Payload do JWT**:
  ```json
  {
    "sub": "user_id",
    "id": "user_id",
    "email": "user@example.com",
    "nome": "Nome Completo",
    "perfil": "ADMIN | USER | SUPER_ADMIN",
    "company_id": "uuid"
  }
  ```

### Multi-Tenant (Isolamento por Empresa)
- Todas as tabelas de negócio possuem `company_id`
- Middleware injeta `company_id` do JWT no `req.usuario`
- Todas as queries **DEVEM** filtrar por `company_id`
- RLS (Row-Level Security) opcional no PostgreSQL para segunda camada

### Roles/Perfis
- **SUPER_ADMIN**: Acesso total (suporte/auditoria)
- **ADMIN**: Gerencia empresa e usuários do próprio tenant
- **USER**: Acesso padrão aos recursos do tenant

### Rate Limiting
- Rotas de autenticação: 10 req/15min por IP
- Protege contra brute force

---

## 🗄️ Banco de Dados

### Estrutura Principal

```
companies (id, type, document, name)
  └─ users (id, company_id, full_name, email, password_hash, role)
  └─ jobs (id, company_id, title, description, ...)
  └─ candidates (id, company_id, full_name, email, ...)
  └─ applications (id, company_id, job_id, candidate_id, ...)
  └─ interviews (id, company_id, application_id, ...)
  └─ resumes (id, company_id, candidate_id, file_id, ...)
  └─ files (id, company_id, storage_key, filename, ...)
  └─ audit_logs (id, company_id, user_id, entity, action, ...)
  └─ refresh_tokens (id, user_id, token, expires_at, revoked_at)
  └─ password_resets (id, user_id, token, expires_at, used_at)
```

### Migrations
Execute `npm run db:apply` para aplicar todas as migrations em `backend/scripts/sql/*.sql`

---

## 🐛 Troubleshooting

### Backend não inicia
- Verifique se PostgreSQL está rodando
- Confirme as credenciais no `.env`
- Rode `npm run db:ping` para testar conexão
- Verifique logs de erro no console

### Erro "Token inválido" no login
- Verifique se `JWT_SECRET` está configurado no `.env`
- Certifique-se de usar a mesma secret em dev/prod
- Limpe refresh tokens antigos no banco

### Frontend não conecta ao backend
- Confirme que backend está rodando em `http://localhost:4000`
- Verifique CORS no backend (`.env`: `CORS_ORIGIN=http://localhost:8080`)
- Abra DevTools e verifique erros de rede

### Erro "company_id não encontrado"
- Faça logout e login novamente
- Token JWT pode estar desatualizado
- Verifique se usuário possui `company_id` no banco

---

## 📝 Próximos Passos (Roadmap)

### Crítico (MVP)
1. ✅ Implementar endpoints CRUD: `/api/jobs`, `/api/candidates`, `/api/applications`
2. ✅ Implementar upload de currículos: `/api/resumes/upload`
3. ✅ Criar tela de cadastro no Flutter
4. ✅ Implementar guards de rota no Flutter
5. ✅ Remover todos os mocks do frontend
6. ✅ Conectar todas as telas ao backend real

### Importante
7. Adicionar helmet e rate limiting global
8. Implementar auditoria automática (audit middleware)
9. Criar collection completa de requests.http
10. Adicionar testes unitários básicos
11. Implementar parse de currículos (PDF/DOCX)
12. Integração opcional com GitHub API
13. Integração com OpenAI para análise de currículos

### Nice to Have
14. Notificações em tempo real (WebSockets)
15. Dashboard com métricas
16. Export de relatórios (PDF)
17. Agendamento de entrevistas (integração calendário)
18. Testes e2e automatizados
19. CI/CD pipeline
20. Deploy em cloud (AWS/Azure/GCP)

---

## 🤝 Contribuindo

1. Crie uma branch para sua feature: `git checkout -b feature/minha-feature`
2. Commit suas mudanças: `git commit -m 'feat: adiciona nova funcionalidade'`
3. Push para a branch: `git push origin feature/minha-feature`
4. Abra um Pull Request

---

## 📄 Licença

Este projeto é privado e proprietário.

---

## 📧 Suporte

Para dúvidas ou problemas, entre em contato com a equipe de desenvolvimento.

**Status**: 🚧 Em desenvolvimento ativo
**Última atualização**: Novembro 2025
