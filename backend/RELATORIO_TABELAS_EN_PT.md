# 📊 Relatório de Análise de Tabelas EN → PT-BR

**Data:** 29/11/2025  
**Projeto:** TalentMatchIA  
**Responsável:** Backend/DBA

---

## 📋 1. Mapeamento de Tabelas: Inglês → Português

| # | Tabela em Inglês (EN) | Tabela em Português (PT-BR) | Status no Backend |
|---|----------------------|----------------------------|-------------------|
| 1 | `users` | `usuarios` | ✅ PT-BR em uso |
| 2 | `companies` | `empresas`* | ⚠️ EN em uso |
| 3 | `sessions` | `sessoes` | ❌ Não utilizada |
| 4 | `refresh_tokens` | `tokens_atualizacao` | ✅ PT-BR em uso |
| 5 | `password_resets` | `redefinicao_senhas` | ✅ PT-BR em uso |
| 6 | `api_keys` | `chaves_api` | ✅ PT-BR em uso |
| 7 | `jobs` | `vagas` | ✅ PT-BR em uso |
| 8 | `job_revisions` | `revisoes_vagas` | ✅ PT-BR em uso |
| 9 | `candidates` | `candidatos` | ✅ PT-BR em uso |
| 10 | `skills` | `habilidades` | ✅ PT-BR em uso |
| 11 | `candidate_skills` | `habilidades_candidato` | ✅ PT-BR em uso |
| 12 | `job_skills` | `habilidades_vaga` | ❌ Não utilizada |
| 13 | `applications` | `candidaturas` | ✅ PT-BR em uso |
| 14 | `application_status_history` | `historico_status_candidatura` | ❌ Não utilizada |
| 15 | `application_stages` | `etapas_candidatura` | ❌ Não utilizada |
| 16 | `notes` | `anotacoes` | ❌ Não utilizada |
| 17 | `resumes` | `curriculos` | ✅ PT-BR em uso |
| 18 | `resume_analysis` | `analise_curriculos` | ⚠️ **AMBAS em uso** |
| 19 | `resume_processing_stats` | `estatisticas_processamento_curriculo` | ✅ PT-BR em uso |
| 20 | `interviews` | `entrevistas` | ✅ PT-BR em uso |
| 21 | `interview_sessions` | `sessoes_entrevista` | ✅ PT-BR em uso |
| 22 | `interview_questions` | `perguntas_entrevista` | ⚠️ **AMBAS em uso** |
| 23 | `interview_answers` | `respostas_entrevista` | 🔴 EN em uso |
| 24 | `interview_messages` | `mensagens_entrevista` | ✅ PT-BR em uso |
| 25 | `ai_feedback` | `feedback_ia` | ❌ Não utilizada |
| 26 | `interview_reports` | `relatorios_entrevista` | ⚠️ **AMBAS em uso** |
| 27 | `files` | `arquivos` | ⚠️ **AMBAS em uso** |
| 28 | `audit_logs` | `logs_auditoria` | 🔴 EN em uso |
| 29 | `calendar_events` | `eventos_calendario` | ✅ PT-BR em uso |
| 30 | `ingestion_jobs` | `processos_ingestao` | 🔴 EN em uso |
| 31 | `pipelines` | `pipelines` | 🔴 EN em uso |
| 32 | `pipeline_stages` | `etapas_pipeline` | ✅ PT-BR em uso |
| 33 | `dashboard_presets` | - | 🔴 EN em uso |
| 34 | `interview_question_sets` | - | 🔴 EN em uso |
| 35 | `live_assessments` | - | 🔴 EN em uso |
| 36 | `candidate_github_profiles` | `perfis_github_candidato` | 🔴 EN em uso |

**Legenda:**
- ✅ PT-BR em uso: Backend já utiliza a versão pt-BR
- 🔴 EN em uso: Backend ainda usa a versão em inglês
- ⚠️ AMBAS em uso: Backend usa tanto EN quanto PT-BR (inconsistência)
- ❌ Não utilizada: Tabela não encontrada em uso no backend

---

## 🔴 2. Tabelas em Inglês AINDA EM USO no Backend

### 2.1 Tabelas que precisam ser migradas para PT-BR

| Tabela EN | Arquivos que Usam | Ação Necessária |
|-----------|-------------------|-----------------|
| `resume_analysis` | `interviews.js` (linhas 225, 306) | Migrar para `analise_curriculos` |
| `interview_questions` | `reports.js`, `live-assessments.js`, `interview-question-sets.js` | Migrar para `perguntas_entrevista` |
| `interview_answers` | `reports.js`, `live-assessments.js` | Migrar para `respostas_entrevista` |
| `interview_reports` | `reports.js` (várias linhas) | Migrar para `relatorios_entrevista` |
| `files` | `files.js` (linha 51) | Migrar para `arquivos` |
| `audit_logs` | `middlewares/audit.js` (linha 8) | Migrar para `logs_auditoria` |
| `ingestion_jobs` | `ingestion.js` (linha 9) | Criar equivalente pt-BR |
| `pipelines` | `pipelines.js`, `applications.js` | Manter (nome técnico universal) |
| `dashboard_presets` | `dashboard.js` | Criar equivalente pt-BR |
| `interview_question_sets` | `interview-question-sets.js` | Criar equivalente pt-BR |
| `live_assessments` | `live-assessments.js` | Criar equivalente pt-BR |
| `candidate_github_profiles` | `github.js` | Migrar para `perfis_github_candidato` |
| `interviews` | `live-assessments.js` (linha 62) | Migrar para `entrevistas` |

### 2.2 Detalhamento por Arquivo

#### `backend/src/api/rotas/interviews.js`
```
Linha 225: FROM resume_analysis ra → FROM analise_curriculos ra
Linha 306: FROM resume_analysis ra → FROM analise_curriculos ra
```

#### `backend/src/api/rotas/reports.js`
```
Linha 97-98: interview_answers, interview_questions → respostas_entrevista, perguntas_entrevista
Linha 99: live_assessments → avaliacoes_tempo_real
Linha 159, 167, 332, 359, 402, 456, 557, 595, 646: interview_reports → relatorios_entrevista
```

#### `backend/src/api/rotas/live-assessments.js`
```
Linha 62: interviews → entrevistas
Linha 82, 90: interview_questions, interview_answers → perguntas_entrevista, respostas_entrevista
Múltiplas linhas: live_assessments → avaliacoes_tempo_real
```

#### `backend/src/api/rotas/files.js`
```
Linha 51: FROM files → FROM arquivos
```

#### `backend/src/middlewares/audit.js`
```
Linha 8: INSERT INTO audit_logs → INSERT INTO logs_auditoria
```

#### `backend/src/api/rotas/github.js`
```
Múltiplas linhas: candidate_github_profiles → perfis_github_candidato
```

---

## ✅ 3. Tabelas em Inglês que Podem ser Removidas

As seguintes tabelas em inglês **NÃO estão sendo utilizadas** no backend e possuem equivalentes em pt-BR:

| Tabela EN | Equivalente PT-BR | Script SQL |
|-----------|------------------|------------|
| `users` | `usuarios` | `DROP TABLE IF EXISTS users CASCADE;` |
| `sessions` | `sessoes` | `DROP TABLE IF EXISTS sessions CASCADE;` |
| `refresh_tokens` | `tokens_atualizacao` | `DROP TABLE IF EXISTS refresh_tokens CASCADE;` |
| `password_resets` | `redefinicao_senhas` | `DROP TABLE IF EXISTS password_resets CASCADE;` |
| `api_keys` | `chaves_api` | `DROP TABLE IF EXISTS api_keys CASCADE;` |
| `jobs` | `vagas` | `DROP TABLE IF EXISTS jobs CASCADE;` |
| `job_revisions` | `revisoes_vagas` | `DROP TABLE IF EXISTS job_revisions CASCADE;` |
| `candidates` | `candidatos` | `DROP TABLE IF EXISTS candidates CASCADE;` |
| `skills` | `habilidades` | `DROP TABLE IF EXISTS skills CASCADE;` |
| `candidate_skills` | `habilidades_candidato` | `DROP TABLE IF EXISTS candidate_skills CASCADE;` |
| `job_skills` | `habilidades_vaga` | `DROP TABLE IF EXISTS job_skills CASCADE;` |
| `applications` | `candidaturas` | `DROP TABLE IF EXISTS applications CASCADE;` |
| `application_status_history` | `historico_status_candidatura` | `DROP TABLE IF EXISTS application_status_history CASCADE;` |
| `application_stages` | `etapas_candidatura` | `DROP TABLE IF EXISTS application_stages CASCADE;` |
| `notes` | `anotacoes` | `DROP TABLE IF EXISTS notes CASCADE;` |
| `resumes` | `curriculos` | `DROP TABLE IF EXISTS resumes CASCADE;` |
| `interview_sessions` | `sessoes_entrevista` | `DROP TABLE IF EXISTS interview_sessions CASCADE;` |
| `interview_messages` | `mensagens_entrevista` | `DROP TABLE IF EXISTS interview_messages CASCADE;` |
| `ai_feedback` | `feedback_ia` | `DROP TABLE IF EXISTS ai_feedback CASCADE;` |
| `calendar_events` | `eventos_calendario` | `DROP TABLE IF EXISTS calendar_events CASCADE;` |

### Tabelas Auxiliares Não Utilizadas (sem equivalente pt-BR):
| Tabela EN | Script SQL |
|-----------|------------|
| `transcriptions` | `DROP TABLE IF EXISTS transcriptions CASCADE;` |
| `webhooks_endpoints` | `DROP TABLE IF EXISTS webhooks_endpoints CASCADE;` |
| `webhooks_events` | `DROP TABLE IF EXISTS webhooks_events CASCADE;` |
| `webhooks_logs` | `DROP TABLE IF EXISTS webhooks_logs CASCADE;` |
| `notifications` | `DROP TABLE IF EXISTS notifications CASCADE;` |
| `github_profiles` | `DROP TABLE IF EXISTS github_profiles CASCADE;` |
| `github_repositories` | `DROP TABLE IF EXISTS github_repositories CASCADE;` |
| `tags` | `DROP TABLE IF EXISTS tags CASCADE;` |
| `job_tags` | `DROP TABLE IF EXISTS job_tags CASCADE;` |
| `candidate_tags` | `DROP TABLE IF EXISTS candidate_tags CASCADE;` |
| `experiences` | `DROP TABLE IF EXISTS experiences CASCADE;` |
| `educations` | `DROP TABLE IF EXISTS educations CASCADE;` |

---

## 🔧 4. Script SQL de Limpeza (Tabelas Não Utilizadas)

O script completo foi gerado em:
```
backend/scripts/sql/035_cleanup_english_tables.sql
```

### Script de Execução Segura:

```sql
-- Execute APENAS após confirmar que o backend não depende dessas tabelas
BEGIN;

-- Tabelas auxiliares não utilizadas
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS ai_feedback CASCADE;
DROP TABLE IF EXISTS application_status_history CASCADE;
DROP TABLE IF EXISTS application_stages CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS job_skills CASCADE;
DROP TABLE IF EXISTS transcriptions CASCADE;
DROP TABLE IF EXISTS webhooks_endpoints CASCADE;
DROP TABLE IF EXISTS webhooks_events CASCADE;
DROP TABLE IF EXISTS webhooks_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS github_profiles CASCADE;
DROP TABLE IF EXISTS github_repositories CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS job_tags CASCADE;
DROP TABLE IF EXISTS candidate_tags CASCADE;
DROP TABLE IF EXISTS experiences CASCADE;
DROP TABLE IF EXISTS educations CASCADE;

-- Tabelas principais com equivalente pt-BR
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS jobs CASCADE;
DROP TABLE IF EXISTS candidates CASCADE;
DROP TABLE IF EXISTS resumes CASCADE;
DROP TABLE IF EXISTS applications CASCADE;
DROP TABLE IF EXISTS refresh_tokens CASCADE;
DROP TABLE IF EXISTS password_resets CASCADE;
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS interview_sessions CASCADE;
DROP TABLE IF EXISTS interview_messages CASCADE;
DROP TABLE IF EXISTS skills CASCADE;
DROP TABLE IF EXISTS candidate_skills CASCADE;
DROP TABLE IF EXISTS job_revisions CASCADE;
DROP TABLE IF EXISTS calendar_events CASCADE;

COMMIT;
```

---

## 📝 5. Pontos de Ajuste no Backend (Prioridade Alta)

### 5.1 CRÍTICO - Tabelas em inglês que PRECISAM ser migradas antes do DROP

| Prioridade | Arquivo | Tabela EN → PT-BR | Impacto |
|------------|---------|-------------------|---------|
| 🔴 ALTA | `reports.js` | `interview_reports` → `relatorios_entrevista` | RF7 - Relatórios |
| 🔴 ALTA | `reports.js` | `interview_questions` → `perguntas_entrevista` | RF7 |
| 🔴 ALTA | `reports.js` | `interview_answers` → `respostas_entrevista` | RF7 |
| 🔴 ALTA | `live-assessments.js` | `live_assessments` → criar tabela pt-BR | RF6 |
| 🔴 ALTA | `live-assessments.js` | `interviews` → `entrevistas` | RF6 |
| 🟡 MÉDIA | `interviews.js` | `resume_analysis` → `analise_curriculos` | RF3 |
| 🟡 MÉDIA | `files.js` | `files` → `arquivos` | Infraestrutura |
| 🟡 MÉDIA | `audit.js` | `audit_logs` → `logs_auditoria` | Auditoria |
| 🟡 MÉDIA | `github.js` | `candidate_github_profiles` → `perfis_github_candidato` | RF4 |
| 🟢 BAIXA | `dashboard.js` | `dashboard_presets` → criar tabela pt-BR | RF9 |
| 🟢 BAIXA | `interview-question-sets.js` | `interview_question_sets` → criar tabela pt-BR | RF3 |
| 🟢 BAIXA | `ingestion.js` | `ingestion_jobs` → criar tabela pt-BR | Infraestrutura |

### 5.2 Ordem de Execução Recomendada

1. **Fase 1 - Migrar código backend** (SEM tocar no banco)
   - Atualizar todas as queries para usar tabelas pt-BR
   - Testar exaustivamente

2. **Fase 2 - Criar tabelas pt-BR faltantes**
   - `avaliacoes_tempo_real` (para `live_assessments`)
   - `conjuntos_perguntas_entrevista` (para `interview_question_sets`)
   - `presets_dashboard` (para `dashboard_presets`)
   - `processos_ingestao` (para `ingestion_jobs`)

3. **Fase 3 - Migrar dados** (se necessário)
   - Copiar dados das tabelas EN para PT-BR

4. **Fase 4 - Executar script de limpeza**
   - Executar `035_cleanup_english_tables.sql`

---

## 📊 6. Resumo Executivo

| Métrica | Quantidade |
|---------|------------|
| Total de tabelas mapeadas | 36 |
| Tabelas pt-BR em uso correto | 18 |
| Tabelas EN ainda em uso | 13 |
| Tabelas não utilizadas (pode remover) | 32 |
| Arquivos backend que precisam ajuste | 8 |

### Próximos Passos Imediatos:

1. ✅ Script SQL de limpeza gerado: `035_cleanup_english_tables.sql`
2. ⏳ Aguardar refatoração do backend (arquivos listados acima)
3. ⏳ Testar todas as rotas após refatoração
4. ⏳ Executar script de limpeza em ambiente de homologação
5. ⏳ Validar integridade dos dados
6. ⏳ Aplicar em produção

---

**Status:** 🟡 PARCIALMENTE BLOQUEADO  
**Motivo:** Backend ainda possui dependências de tabelas em inglês  
**Próxima Ação:** Refatorar arquivos listados na seção 5.1
