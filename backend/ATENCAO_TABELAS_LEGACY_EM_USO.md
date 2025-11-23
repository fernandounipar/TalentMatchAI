# ⚠️ ATENÇÃO: Tabelas Legacy Ainda em Uso

## Status: 🔴 NÃO REMOVER AINDA

Durante a análise para remoção das tabelas legacy (em português), foi identificado que **ainda existem referências no código backend**.

---

## 📋 Referências Encontradas

### 1. `backend/src/api/rotas/entrevistas.js` (LEGACY)

**Tabelas usadas:**
- `entrevistas`
- `perguntas`
- `relatorios`
- `mensagens`

**Linhas afetadas:**
- Linha 13: `FROM entrevistas e`
- Linha 19: `FROM perguntas WHERE entrevista_id=$1`
- Linha 20: `FROM relatorios WHERE entrevista_id=$1`
- Linha 28: `FROM entrevistas e`
- Linha 49: `FROM perguntas WHERE entrevista_id=$1`
- Linha 67: `FROM mensagens WHERE entrevista_id=$1`
- Linha 84: `FROM entrevistas e`
- Linha 95: `FROM mensagens WHERE entrevista_id=$1`

**Tipo de rota:** `/api/entrevistas` (legado)

---

### 2. `backend/src/api/rotas/interviews.js` (PARCIALMENTE MIGRADO)

**Tabelas usadas:**
- `mensagens` (tabela legacy em português)

**Linhas afetadas:**
- Linha 319: `FROM mensagens WHERE entrevista_id=$1`
- Linha 363: `FROM mensagens WHERE entrevista_id=$1`

**Observação:** Este arquivo é o novo domínio (`/api/interviews`), mas ainda tem queries para a tabela antiga `mensagens` ao invés de usar `interview_messages`.

---

### 3. `backend/src/api/rotas/historico.js`

**Tabelas usadas:**
- `entrevistas`
- `relatorios`

**Linhas afetadas:**
- Linha 41: `FROM relatorios r2 WHERE r2.entrevista_id = e.id`
- Linha 42: `FROM entrevistas e`

**Observação:** Rota de histórico mistura entidades novas e legadas.

---

## 🔧 AÇÕES NECESSÁRIAS ANTES DA REMOÇÃO

### 1. Migrar `backend/src/api/rotas/interviews.js` 🔴 CRÍTICO

**Problema:** Ainda usa tabela `mensagens` legada

**Solução:**
```javascript
// ANTES (linha 319 e 363)
'SELECT role, conteudo FROM mensagens WHERE entrevista_id=$1...'

// DEPOIS (usar nova tabela)
'SELECT sender as role, message as conteudo FROM interview_messages WHERE interview_id=$1...'
```

**Impacto:** 
- Rotas de chat (`/api/interviews/:id/chat`, `/api/interviews/:id/messages`)
- ✅ Tabela `interview_messages` já existe e está pronta (Migration 030)

---

### 2. Deprecar `backend/src/api/rotas/entrevistas.js` 🟡 IMPORTANTE

**Opções:**

#### Opção A: Remover completamente
- Deletar arquivo `backend/src/api/rotas/entrevistas.js`
- Remover do `backend/src/api/index.js`
- Confirmar que frontend não usa `/api/entrevistas`

#### Opção B: Redirecionar para nova rota
```javascript
// Em entrevistas.js (legado)
router.get('/:id', (req, res) => {
  res.redirect(308, `/api/interviews/${req.params.id}`);
});
```

**Recomendação:** Opção A (remoção), se frontend já usa `/api/interviews`

---

### 3. Atualizar `backend/src/api/rotas/historico.js` 🟡 IMPORTANTE

**Problema:** Queries usam tabelas `entrevistas` e `relatorios` legadas

**Solução:**
```sql
-- ANTES
FROM entrevistas e
EXISTS(SELECT 1 FROM relatorios r2 WHERE r2.entrevista_id = e.id)

-- DEPOIS
FROM interviews i
EXISTS(SELECT 1 FROM interview_reports ir WHERE ir.interview_id = i.id)
```

**Impacto:**
- Rota `/api/historico`
- Necessário ajustar nomes de colunas (português → inglês)

---

## 📝 PLANO DE MIGRAÇÃO

### Fase 1: Atualizar Rotas Existentes ✅

1. **Atualizar `interviews.js`** (linhas 319, 363)
   - Trocar `mensagens` → `interview_messages`
   - Trocar `conteudo` → `message`
   - Trocar `entrevista_id` → `interview_id`
   - Trocar `role` → `sender`

2. **Atualizar `historico.js`** (linhas 41-42)
   - Trocar `entrevistas` → `interviews`
   - Trocar `relatorios` → `interview_reports`
   - Ajustar nomes de colunas

### Fase 2: Remover/Deprecar Legado 🔴

3. **Desabilitar rota legada**
   - Remover `app.use('/api/entrevistas', ...)` de `index.js`
   - OU adicionar middleware de deprecação:
   ```javascript
   router.use((req, res) => {
     res.status(410).json({
       error: {
         code: 'ROUTE_DEPRECATED',
         message: 'Esta rota foi descontinuada. Use /api/interviews',
         new_endpoint: req.originalUrl.replace('/entrevistas', '/interviews')
       }
     });
   });
   ```

### Fase 3: Validar e Testar ✅

4. **Testes de Integração**
   - [ ] Testar todas as rotas de `/api/interviews`
   - [ ] Testar `/api/historico`
   - [ ] Confirmar que frontend não usa `/api/entrevistas`
   - [ ] Validar no ambiente de dev

### Fase 4: Executar Migration 031 🎯

5. **Remover tabelas legacy**
   ```bash
   node scripts/aplicar_migration_031.js
   ```
   - Script irá pedir confirmação
   - Removerá: mensagens, perguntas, relatorios, entrevistas, curriculos, candidatos, vagas

---

## 🔍 VERIFICAÇÃO FINAL

Antes de executar Migration 031, confirme:

- [ ] Nenhum arquivo em `backend/src` referencia tabelas legacy
- [ ] Frontend não usa rotas `/api/entrevistas` antigas
- [ ] Backup dos dados foi feito (se necessário)
- [ ] Testes passam com as novas rotas
- [ ] Código foi commitado antes da remoção

**Comando para verificar referências:**
```bash
# No diretório backend/src
grep -r "FROM\s\+\(mensagens\|perguntas\|relatorios\|entrevistas\|curriculos\|candidatos\|vagas\)" . --include="*.js"
```

---

## 📊 RESUMO

| Tabela Legacy | Status | Referências | Ação Necessária |
|---------------|--------|-------------|-----------------|
| mensagens | 🔴 EM USO | interviews.js (2x) | Migrar para `interview_messages` |
| perguntas | 🔴 EM USO | entrevistas.js (2x) | Deprecar rota legada |
| relatorios | 🔴 EM USO | entrevistas.js, historico.js | Migrar para `interview_reports` |
| entrevistas | 🔴 EM USO | entrevistas.js (3x), historico.js | Migrar para `interviews` |
| curriculos | ✅ SEM USO | - | Pode remover |
| candidatos | ✅ SEM USO | - | Pode remover |
| vagas | ✅ SEM USO | - | Pode remover |

---

## 🎯 PRÓXIMO PASSO IMEDIATO

**Recomendação:** Solicitar ao **Alex** (desenvolvedor backend) que:

1. Atualize `interviews.js` para usar `interview_messages`
2. Atualize `historico.js` para usar `interviews` e `interview_reports`
3. Remova ou deprecie `entrevistas.js` (rota legada)
4. Teste todas as rotas afetadas
5. Confirme que migration 031 pode ser executada

Após essas mudanças, será seguro executar a **Migration 031** para remover as tabelas legacy.

---

**Status Atual:** 🔴 **BLOQUEADO** - Aguardando refatoração do backend  
**Responsável pela próxima ação:** Alex (Backend Developer)  
**Documento preparado por:** David (DBA)  
**Data:** 23/11/2025
