# 🧪 TESTE - Campos de Perfil do Usuário (Cargo e Foto)

## 📋 Resumo da Implementação

Implementação completa de:
1. **Campo "Cargo"** com 3 opções: Admin, Recrutador(a), Gestor(a)
2. **Upload de foto** do usuário (avatar)
3. **Exibição da foto** na sidebar
4. **Persistência no banco de dados**

---

## 🗄️ Passo 1: Aplicar Migration no Banco de Dados

### 1.1 Executar migration

```powershell
cd backend
node scripts/aplicar_migration_009.js
```

**Resultado esperado:**
```
✅ Migration 009 aplicada com sucesso!
📋 Campos adicionados:
   - users.cargo (VARCHAR 50)
   - users.foto_url (TEXT)
```

### 1.2 Verificar colunas criadas

```powershell
node scripts/db_table_columns.js users
```

**Deve aparecer:**
- `cargo` (character varying, 50)
- `foto_url` (text)

---

## 🚀 Passo 2: Iniciar Backend e Frontend

### 2.1 Backend

```powershell
cd backend
.\start-server.bat
```

### 2.2 Frontend (novo terminal)

```powershell
cd frontend
flutter run -d chrome
```

---

## 🧪 Passo 3: Testar Funcionalidades

### 3.1 Login

1. Acesse a aplicação
2. Faça login com: `fernando@email.com` / `god0702`

✅ **Verificar:** Sidebar exibe "FM" (iniciais) ou foto se já configurada

---

### 3.2 Configurar Cargo

1. Navegue para **Configurações**
2. Clique na aba **"Perfil"**
3. No dropdown **"Cargo"**, selecione: **"Recrutador(a)"**
4. Clique em **"Salvar Alterações"**

✅ **Resultado esperado:**
- Mensagem: "✅ Perfil atualizado com sucesso!"
- Página recarrega automaticamente
- Cargo salvo no banco de dados

---

### 3.3 Atualizar Foto do Usuário

1. Na mesma tela (**Perfil**), clique em **"Alterar Foto"**
2. Digite uma URL de imagem (exemplo):
   ```
   https://i.pravatar.cc/150?img=12
   ```
3. Clique em **"Salvar"**

✅ **Resultado esperado:**
- Mensagem: "✅ Foto atualizada com sucesso!"
- **Avatar na sidebar** agora exibe a foto (ao invés das iniciais "FM")
- Foto persiste após logout/login

---

### 3.4 Verificar Persistência

1. Faça **logout**
2. Faça **login** novamente
3. Navegue para **Configurações → Perfil**

✅ **Verificar:**
- Cargo selecionado está salvo
- Foto do usuário aparece no avatar (sidebar + tela de perfil)

---

### 3.5 Verificar no Banco de Dados

Execute SQL para conferir os dados:

```sql
SELECT id, full_name, email, cargo, foto_url 
FROM users 
WHERE email = 'fernando@email.com';
```

✅ **Resultado esperado:**
```
| id | full_name        | email               | cargo          | foto_url                          |
|----|------------------|---------------------|----------------|-----------------------------------|
| 1  | Fernando Marques | fernando@email.com  | Recrutador(a)  | https://i.pravatar.cc/150?img=12 |
```

---

## 🔍 Passo 4: Testar Edge Cases

### 4.1 Cargo Nulo

1. Selecione **"Selecione um cargo"** (opção vazia)
2. Salve

✅ **Resultado:** Cargo fica NULL no banco, dropdown exibe "Selecione um cargo" novamente

---

### 4.2 URL de Foto Inválida

1. Clique em "Alterar Foto"
2. Digite: `url_invalida`
3. Salve

✅ **Resultado:** Foto salva, mas avatar não exibe (fallback para iniciais)

---

### 4.3 Remover Foto

1. Clique em "Alterar Foto"
2. Digite: ` ` (espaço vazio ou string vazia)
3. Salve

✅ **Resultado:** Foto removida, avatar volta a exibir iniciais

---

## 📡 Passo 5: Testar Endpoints da API

### 5.1 PUT /api/user/profile (Atualizar Perfil)

```powershell
# Obter token primeiro (login)
curl -X POST http://localhost:3000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"fernando@email.com","password":"god0702"}'

# Copie o accessToken e use no próximo comando
curl -X PUT http://localhost:3000/api/user/profile `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer SEU_ACCESS_TOKEN" `
  -d '{"full_name":"Fernando Marques","cargo":"Gestor(a)"}'
```

✅ **Resultado esperado (Status 200):**
```json
{
  "mensagem": "Perfil atualizado com sucesso",
  "user": {
    "id": "...",
    "full_name": "Fernando Marques",
    "email": "fernando@email.com",
    "role": "USER",
    "cargo": "Gestor(a)",
    "foto_url": "..."
  }
}
```

---

### 5.2 POST /api/user/avatar (Atualizar Foto)

```powershell
curl -X POST http://localhost:3000/api/user/avatar `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer SEU_ACCESS_TOKEN" `
  -d '{"foto_url":"https://i.pravatar.cc/150?img=25"}'
```

✅ **Resultado esperado (Status 200):**
```json
{
  "mensagem": "Foto atualizada com sucesso",
  "user": {
    "id": "...",
    "full_name": "Fernando Marques",
    "foto_url": "https://i.pravatar.cc/150?img=25"
  }
}
```

---

### 5.3 GET /api/user/me (Verificar Dados)

```powershell
curl http://localhost:3000/api/user/me `
  -H "Authorization: Bearer SEU_ACCESS_TOKEN"
```

✅ **Resultado esperado:**
```json
{
  "user": {
    "id": "...",
    "company_id": "...",
    "full_name": "Fernando Marques",
    "email": "fernando@email.com",
    "role": "USER",
    "is_active": true,
    "cargo": "Gestor(a)",
    "foto_url": "https://i.pravatar.cc/150?img=25"
  },
  "company": { ... }
}
```

---

## ✅ Checklist Final

- [ ] Migration 009 aplicada com sucesso
- [ ] Colunas `cargo` e `foto_url` existem na tabela `users`
- [ ] Backend iniciado sem erros
- [ ] Frontend compilado sem erros
- [ ] Login funciona
- [ ] Dropdown de cargo exibe 3 opções: Admin, Recrutador(a), Gestor(a)
- [ ] Cargo salva no banco ao clicar em "Salvar Alterações"
- [ ] Upload de foto por URL funciona
- [ ] Avatar na sidebar exibe foto quando configurada
- [ ] Avatar na sidebar exibe iniciais quando não há foto
- [ ] Dados persistem após logout/login
- [ ] Endpoint PUT /api/user/profile funciona
- [ ] Endpoint POST /api/user/avatar funciona
- [ ] Endpoint GET /api/user/me retorna cargo e foto_url

---

## 🐛 Problemas Comuns

### Migration falha: "relation 'users' does not exist"

**Solução:** Execute migrações anteriores primeiro:
```powershell
node scripts/db_apply.js
```

---

### Backend retorna erro 500 ao salvar cargo

**Verificar:** Se coluna `cargo` existe:
```sql
\d users
```

---

### Foto não aparece na sidebar

**Verificar:**
1. URL da foto está válida?
2. Console do navegador mostra erro de CORS?
3. Campo `foto_url` está populado no banco?

---

## 📝 Notas Técnicas

- **Valores válidos para `cargo`:** `'Admin'`, `'Recrutador(a)'`, `'Gestor(a)'`, `NULL`
- **`foto_url`** pode ser qualquer URL (http/https) ou `NULL`
- **Avatar** usa `NetworkImage` para carregar foto
- **Fallback** para iniciais se `foto_url` for `NULL` ou inválida
- **Sidebar** atualiza automaticamente após salvar perfil

---

**🚀 Boa sorte nos testes!**
