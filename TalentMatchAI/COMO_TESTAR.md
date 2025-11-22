# 🧪 Como Testar a Plataforma TalentMatchIA

## ✅ Pré-requisitos

Antes de começar, certifique-se de que você tem instalado:

- **Node.js** (v18 ou superior)
- **PostgreSQL** (rodando localmente ou remoto)
- **Flutter** (v3.33 ou superior)
- **Git Bash** ou **PowerShell**

---

## 📦 Passo 1: Verificar Conexão com o Banco de Dados

### 1.1 Abra o CMD/PowerShell na pasta do projeto

```powershell
cd "c:\Users\Fernando\Documents\Faculdade - ADS\TalentMatchAI"
```

### 1.2 Teste a conexão com o PostgreSQL

```powershell
cd backend
node scripts/db_ping.js
```

**Resultado esperado:**
```
✅ Conexão com o banco bem-sucedida!
Database: talentmatchia_dev
Host: localhost
Port: 5432
```

### 1.3 Verificar se as tabelas existem

```powershell
node scripts/db_tables.js
```

**Resultado esperado:** Lista de todas as tabelas (`companies`, `users`, `jobs`, etc.)

### 1.4 (Opcional) Verificar dados de teste

```powershell
node scripts/db_counts.js
```

Mostra quantos registros existem em cada tabela.

---

## 🚀 Passo 2: Iniciar o Backend

### 2.1 Instalar dependências (se ainda não instalou)

```powershell
cd backend
npm install
```

### 2.2 Iniciar o servidor

**Opção 1 - Via script batch (recomendado):**
```powershell
.\start-server.bat
```

**Opção 2 - Via npm:**
```powershell
npm start
```

**Resultado esperado:**
```
✅ Servidor rodando na porta 3000
✅ Banco conectado: talentmatchia_dev
```

### 2.3 Testar endpoints manualmente (opcional)

Deixe o servidor rodando e abra **outro terminal** para testar:

```powershell
# Testar health check
curl http://localhost:3000/api/health

# Testar login com usuário existente
node scripts/test_login.js
```

---

## 🎨 Passo 3: Iniciar o Frontend (Flutter Web)

### 3.1 Abrir novo terminal (deixe o backend rodando!)

```powershell
cd "c:\Users\Fernando\Documents\Faculdade - ADS\TalentMatchAI\frontend"
```

### 3.2 Instalar dependências (se ainda não instalou)

```powershell
flutter pub get
```

### 3.3 Iniciar o Flutter Web

```powershell
flutter run -d chrome
```

**Resultado esperado:**
- Navegador Chrome abrirá automaticamente
- Aplicação carregará na URL: `http://localhost:XXXXX`
- Tela de landing page será exibida

---

## 🧪 Passo 4: Testar o Fluxo Completo

### 4.1 Testar Login com Usuário Existente

1. **Acesse a tela de login** (clique em "Entrar" na landing page)

2. **Credenciais de teste:**
   - **Email:** `fernando@email.com`
   - **Senha:** `god0702`

3. **Clique em "Entrar"**

**✅ Resultado esperado:**
- Login bem-sucedido
- Redirecionamento para o Dashboard
- Sidebar exibindo: **"Fernando Marques"** e perfil **"Recrutador"**

---

### 4.2 Verificar Dados Reais na Sidebar

**✅ O que verificar:**
- Nome do usuário logado deve ser **"Fernando Marques"** (não "Recrutadora")
- Perfil deve ser **"Recrutador"** (não hardcoded)
- Botão de logout deve funcionar

---

### 4.3 Testar Tela de Configurações

1. **Clique no menu lateral** → **"Configurações"**

2. **Verifique as abas:**
   - **Aba "Empresa"**: Formulário para cadastrar empresa
   - **Aba "Perfil"**: Dados do usuário logado (nome, email, perfil, status)

3. **Na aba "Perfil", verifique:**
   - **Nome:** Fernando Marques
   - **Email:** fernando@email.com
   - **Perfil:** Recrutador
   - **Status:** Ativo

---

### 4.4 Cadastrar Empresa (Gradual Onboarding)

1. **Vá para a aba "Empresa"**

2. **Preencha o formulário:**
   - **Tipo:** Selecione `CNPJ`
   - **Documento:** `12345678000195` (apenas números)
   - **Nome:** `Tech Recrutadora LTDA`

3. **Clique em "Salvar Empresa"**

**✅ Resultado esperado:**
- Mensagem de sucesso: "✅ Empresa salva com sucesso!"
- Página recarrega automaticamente
- **Sidebar agora exibe:** Perfil **"Administrador"** (mudou de USER → ADMIN)
- Na aba "Empresa", os dados da empresa aparecem (Tipo, Documento, Nome)

---

### 4.5 Testar Logout

1. **Clique no botão "Sair"** na sidebar

**✅ Resultado esperado:**
- Volta para a tela de landing page
- Dados do usuário são limpos
- Tentativa de acessar rotas protegidas redireciona para login

---

## 🐛 Passo 5: Testes de Validação (Edge Cases)

### 5.1 Testar CPF Inválido

1. Login → Configurações → Aba "Empresa"
2. Selecione **"CPF"**
3. Digite um CPF com menos de 11 dígitos: `12345`
4. Clique em "Salvar"

**✅ Resultado esperado:**
- Erro: "CPF deve ter 11 dígitos"

---

### 5.2 Testar CNPJ Inválido

1. Selecione **"CNPJ"**
2. Digite um CNPJ com menos de 14 dígitos: `12345678`
3. Clique em "Salvar"

**✅ Resultado esperado:**
- Erro: "CNPJ deve ter 14 dígitos"

---

### 5.3 Testar Campos Vazios

1. Deixe todos os campos vazios
2. Clique em "Salvar"

**✅ Resultado esperado:**
- Validação no frontend impede envio
- Campos obrigatórios destacados

---

### 5.4 Testar Login com Senha Incorreta

1. Faça logout
2. Tente logar com:
   - **Email:** `fernando@email.com`
   - **Senha:** `senha_errada`

**✅ Resultado esperado:**
- Erro: "Credenciais inválidas"
- Não redireciona para o dashboard

---

## 📊 Passo 6: Testar Outras Telas (Opcional)

### 6.1 Dashboard
- Acesse o Dashboard
- Verifique se os KPIs são exibidos (pode ter dados mockados ainda)

### 6.2 Vagas
- Navegue para "Vagas"
- Verifique listagem de vagas

### 6.3 Candidatos
- Navegue para "Candidatos"
- Verifique listagem de candidatos

---

## 🛠️ Comandos Úteis para Debugging

### Backend

```powershell
# Ver todas as tabelas do banco
node scripts/db_tables.js

# Ver contagem de registros
node scripts/db_counts.js

# Verificar colunas de uma tabela
node scripts/db_table_columns.js users

# Testar login via script
node scripts/test_login.js

# Verificar rotas disponíveis
node scripts/check_routes.js
```

### Frontend

```powershell
# Limpar cache e rebuild
flutter clean
flutter pub get
flutter run -d chrome

# Ver logs detalhados
flutter run -d chrome --verbose

# Build para produção
flutter build web
```

---

## ❌ Problemas Comuns

### Backend não inicia

**Erro:** `ECONNREFUSED localhost:5432`

**Solução:**
1. Verifique se o PostgreSQL está rodando
2. Verifique as credenciais no `.env`
3. Execute `node scripts/db_ping.js` para diagnosticar

---

### Frontend não carrega

**Erro:** `XMLHttpRequest error`

**Solução:**
1. Verifique se o backend está rodando (`http://localhost:3000`)
2. Verifique CORS no backend (já configurado no `server.js`)
3. Limpe o cache: `flutter clean && flutter pub get`

---

### Login falha

**Erro:** `Credenciais inválidas`

**Solução:**
1. Verifique se o usuário existe no banco:
   ```sql
   SELECT * FROM users WHERE email = 'fernando@email.com';
   ```
2. Senha correta: `god0702`
3. Verifique logs do backend no terminal

---

### Sidebar não atualiza após salvar empresa

**Solução:**
1. Faça logout e login novamente
2. Verifique se o campo `company_id` foi preenchido:
   ```sql
   SELECT id, full_name, email, role, company_id FROM users WHERE email = 'fernando@email.com';
   ```
3. O role deve ter mudado de `USER` → `ADMIN`

---

## 📝 Checklist Final

- [ ] Backend iniciado e rodando na porta 3000
- [ ] Banco de dados conectado (`db_ping.js` OK)
- [ ] Frontend iniciado no Chrome
- [ ] Login funciona com `fernando@email.com` / `god0702`
- [ ] Sidebar exibe "Fernando Marques" e "Recrutador"
- [ ] Tela de Configurações carrega dados reais
- [ ] Aba "Perfil" mostra dados do usuário
- [ ] Aba "Empresa" mostra formulário
- [ ] Cadastro de empresa funciona (tipo, documento, nome)
- [ ] Após salvar empresa, role muda para "Administrador"
- [ ] Logout funciona corretamente

---

## 🎯 Próximos Passos

Após validar todos os testes acima:

1. **Implementar outras telas** (Vagas, Candidatos, Entrevistas)
2. **Remover dados mockados** das telas restantes
3. **Adicionar mais validações** (CPF/CNPJ com dígito verificador)
4. **Implementar upload de currículo** (RF1)
5. **Integração com OpenAI API** para análise de currículos

---

**🚀 Boa sorte nos testes!**
