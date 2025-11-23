# 📚 Guia de Uso - Scripts de Migration

## 🎯 Scripts Disponíveis

### 1. Listar Tabelas do Banco
```bash
node scripts/listar_tabelas_db.js
```

**Função:** Lista todas as tabelas classificadas por categoria (MVP, Legacy, Auxiliares)

**Saída:**
- Total de tabelas
- Tabelas MVP (em uso)
- Tabelas Legacy (pt-BR, considerar remoção)
- Tabelas Auxiliares (análise pendente)

---

### 2. Aplicar Migration 030 ✅ JÁ APLICADA
```bash
node scripts/aplicar_migration_030.js
```

**Status:** ✅ CONCLUÍDA em 23/11/2025

**O que faz:**
- Atualiza `interview_questions` (+4 colunas)
- Cria `interview_messages` (nova)
- Expande `interview_reports` (+15 colunas)
- Cria função `get_dashboard_overview()`

**Validações incluídas:**
- Verifica colunas criadas
- Testa índices
- Executa função de dashboard
- Mostra KPIs atuais

---

### 3. Aplicar Migration 031 🔴 BLOQUEADA
```bash
node scripts/aplicar_migration_031.js
```

**Status:** 🔴 **NÃO EXECUTAR AINDA**

**O que faz:**
- Remove 7 tabelas legacy em português
- Tabelas: mensagens, perguntas, relatorios, entrevistas, curriculos, candidatos, vagas

**⚠️ ATENÇÃO:**
- Backend ainda usa essas tabelas
- Leia `ATENCAO_TABELAS_LEGACY_EM_USO.md` antes
- Aguarde refatoração do Alex

**Pré-requisitos:**
1. Backend não pode referenciar tabelas legacy
2. Fazer backup se necessário
3. Testar todas as rotas principais

**Confirmação interativa:**
- Script pede confirmação antes de executar
- Digite "sim" ou "s" para confirmar

---

## 📋 Ordem Recomendada

### Para Primeira Execução

1. **Verificar estado atual:**
   ```bash
   node scripts/listar_tabelas_db.js
   ```

2. **Aplicar Migration 030:** (se ainda não aplicada)
   ```bash
   node scripts/aplicar_migration_030.js
   ```

3. **Aguardar refatoração do backend**
   - Leia `ATENCAO_TABELAS_LEGACY_EM_USO.md`
   - Alex precisa atualizar rotas

4. **Aplicar Migration 031:** (após refatoração)
   ```bash
   node scripts/aplicar_migration_031.js
   ```

---

## 🔧 Troubleshooting

### Erro: "Cannot find module"
```bash
# Certifique-se de estar no diretório correto
cd backend
node scripts/[nome_do_script].js
```

### Erro: "Connection refused"
```bash
# Verifique se PostgreSQL está rodando
# No Windows:
Get-Service -Name postgresql*

# Verifique configurações em .env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=sua_senha
DB_NAME=talentmatchia
```

### Erro: "db.end is not a function"
- Ignorar se migration foi aplicada com sucesso
- Não afeta a execução
- Script será corrigido em próxima versão

---

## 📄 Documentação Relacionada

- **RESUMO_EXECUTIVO_MIGRATION_030.md** - Resumo rápido
- **DAVID_MIGRATION_030_RESUMO.md** - Detalhamento técnico
- **CHECKLIST_FINAL_DATABASE_MVP.md** - Checklist completo
- **ATENCAO_TABELAS_LEGACY_EM_USO.md** - Bloqueio de remoção

---

## ✅ Validação Pós-Migration

Após aplicar qualquer migration, execute:

```bash
# Listar tabelas atualizadas
node scripts/listar_tabelas_db.js

# Verificar logs do backend
npm start

# Testar rotas principais
# Use API_COLLECTION.http ou Postman
```

---

## 🆘 Suporte

Se encontrar problemas:

1. Consulte a documentação em `backend/*.md`
2. Verifique logs de erro completos
3. Confirme variáveis de ambiente no `.env`
4. Entre em contato com David (DBA) ou Alex (Backend)

---

**Última atualização:** 23/11/2025  
**Mantenedor:** David (Analista de Dados / DBA)
