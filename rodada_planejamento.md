# Rodada – Triagem de Currículos (RF1)

## 1. Mike – Líder de Equipe

* Problema foco: **RF1 – Upload e análise de currículos (PDF/TXT)** atendendo RNF1 (tempo < 10s), RNF3 (LGPD) e RNF6 (código modular).
* Objetivo da rodada: entregar fluxo ponta a ponta sem mocks, integrado a banco/IA, alinhado ao layout Figma.
* **Visão de CRUD:** garantir tela(s) para **Cadastrar (upload)**, **Listar**, **Editar metadados** (ex.: marcar favorito, atualizar observações) e **Excluir** currículos/análises, sempre filtrando por `company_id`.
* Tasks abertas:

  * **Iris:** compilar referências de IA aplicada a triagem e LGPD.
  * **Emma:** definir MVP, jornadas, critérios de aceite de RF1 e ações de CRUD na tela de Currículos.
  * **Bob:** desenhar arquitetura (rotas CRUD, segurança, integração IA/DB) e contratos.
  * **Alex:** implementar backend Node.js + frontend Flutter Web para CRUD de currículos e análise.
  * **David:** mapear métricas/KPIs e tabelas/logs para monitorar RF1.

## 2. Iris – Pesquisadora Profunda

* Melhores práticas de IA em triagem:

  * Extrair dados estruturados do currículo com schema JSON (contato, experiências, skills, senioridade) e validação de formato.
  * Usar prompts de extração com raciocínio oculto para melhorar precisão.
* LGPD e vieses:

  * Minimizar coleta, mascarando dados sensíveis (CPF, endereço).
  * Consentimento registrado antes do upload; permitir exclusão sob requisição (ligado ao **Delete** do CRUD).
* Segurança operacional:

  * Sanitizar PDFs, limitar tamanho, aplicar timeouts e evitar registrar conteúdo sensível em logs.

## 3. Emma – Gerente de Produto

* MVP e fluxo de usuário (pensando em CRUD):

  1. **Criar**: Recrutador acessa página *Currículos* e faz upload (PDF/TXT) de um ou mais arquivos, vinculando a uma vaga opcional.
  2. **Listar/Visualizar**: Tela com lista de currículos (filtro por vaga, status, data), com acesso ao detalhamento da análise e histórico.
  3. **Editar**: Recrutador pode atualizar observações internas, marcar o currículo como favorito, alterar vínculo com vaga e reprocessar análise se necessário.
  4. **Excluir**: Recrutador (com permissão) pode excluir currículos/análises, respeitando regras de retenção/LGPD.
* Critérios de aceitação:

  * Upload aceita PDF/TXT até 5MB; falhas retornam mensagem clara.
  * Tempo médio de resposta < 10s em ambiente padrão.
  * Lista de currículos com filtros, paginação e ação rápida (ver, editar, excluir).
  * Ao menos: nome, e-mail mascarado, senioridade inferida, top 5 skills, 3–5 perguntas sugeridas.
  * Dados sempre vinculados a `company_id` e usuário autenticado.

## 4. Bob – Arquiteto de Software

* Backend Node.js (CRUD):

  * Rotas:

    * `POST /api/resumes` – upload/cadastro de currículo (Create).
    * `GET /api/resumes` – listagem paginada com filtros (Read).
    * `GET /api/resumes/:id` – detalhes + análise (Read).
    * `PUT /api/resumes/:id` – atualizar metadados (Edit).
    * `DELETE /api/resumes/:id` – excluir currículo/análise (Delete).
    * `POST /api/resumes/:id/analyze` – (re)analisar currículo.
  * Todas as rotas protegidas por auth, extraindo `user_id` e `company_id`.
  * Serviço de IA encapsulado (`resumeAnalysisService`) com timeout e logs.
* Banco de dados:

  * `resumes(id, candidate_name, email, phone, company_id, user_id, job_id, status, notes, created_at, updated_at, deleted_at)`
  * `resume_analysis(id, resume_id, summary jsonb, questions jsonb, score numeric, created_at)`
  * `analysis_feedback(...)`
  * Soft delete com `deleted_at` para suportar recuperação se necessário.
* Frontend Flutter Web (CRUD):

  * Tela `curriculos_tela.dart` com:

    * Lista com filtros, paginação e ações (ver/editar/excluir).
    * Form de upload (Create).
    * Tela de detalhes com edição de notas e reanálise (Update).
    * Confirmação de exclusão (Delete).
* Segurança/escalabilidade:

  * Todas as consultas filtradas por `company_id`.
  * Rate limiting nas rotas de análise.

## 5. Alex – Engenheiro (implementação)

* Backend:

  * Implementar controllers e services para todas as rotas CRUD de `resumes`.
  * Garantir transação para criação de currículo + análise inicial.
* Frontend:

  * Conectar CRUD de currículos:

    * Form de criação (upload).
    * Lista com ações de visualizar, editar, excluir.
    * Edição inline ou modal para notas/metadados.
* Integração IA:

  * Uso do serviço central de IA, com DTO de resposta padronizado.

## 6. David – Analista de Dados

* Métricas/KPIs:

  * Quantidade de currículos criados (Create), visualizados (Read), atualizados (Update) e excluídos (Delete) por período e `company_id`.
  * Tempo de processamento médio por currículo.
* Implementação:

  * Views `resume_processing_stats` e `resume_crud_stats`.

## 7. Mike – Líder de Equipe (fechamento)

* Validação: critérios de aceitação cumpridos, CRUD funcionando ponta a ponta, filtros por `company_id`.
* Evidências: collection das rotas CRUD, prints da tela de Currículos (lista, criação, edição, exclusão) e consultas no PostgreSQL.

---

## Execução / Checkpoints (RF1)

- [x] Rotas definidas: `POST /api/resumes`, `GET /api/resumes`, `GET /api/resumes/:id`, `PUT /api/resumes/:id`, `DELETE /api/resumes/:id`, `POST /api/resumes/:id/analyze` (todas com auth + `company_id`).
- [x] IA integrada com fallback OpenAI → OpenRouter, timeout e tratamento de erro (sem logar dados sensíveis).
- [x] Contrato de análise padronizado: `summary`, `skills`, `keywords`, `experiences`, `candidato`, `experiencias`, `educacao`, `certificacoes`, `matchingScore`, `pontosFortes`, `pontosAtencao`, `aderenciaRequisitos`, `provider`, `model`.
- [x] Frontend Flutter: tela Currículos com upload (PDF/TXT), lista filtrável/paginada, detalhe com análise, reprocessar, excluir, editar notas/favorito.
- [x] Banco: tabelas `resumes` e `resume_analysis` com RLS por `company_id`, soft delete, índices em `company_id`, `job_id`, `status`, `created_at`.
- [x] LGPD: mascarar email em lista, limitar tamanho (5MB), sanitização básica, consentimento registrado, nada de conteúdo sensível em logs.
- [x] Views de métricas: `resume_processing_stats`, `resume_crud_stats`, `resume_analysis_performance`, `resume_by_job_stats`, `candidate_resume_history`.
- [x] Endpoints de métricas: `/api/dashboard/resumes/metrics`, `/api/dashboard/resumes/timeline`.
- [x] Função SQL: `get_resume_metrics(company_id)` para métricas consolidadas.
- [x] Documentação completa: `backend/RF1_DOCUMENTACAO.md`.
- [x] Collection de testes: `backend/RF1_RESUMES_API_COLLECTION.http`.
- [x] Migrations aplicadas: 012 (colunas), 013 (views de métricas).

### ✅ Rodada RF1 - CONCLUÍDA

**Data de conclusão**: 22 de Novembro de 2025

**Implementações realizadas**:
1. ✅ CRUD completo de currículos (`/api/resumes`)
2. ✅ Integração com IA (OpenAI + OpenRouter fallback)
3. ✅ Extração estruturada: candidato, experiências, educação, certificações
4. ✅ Views de métricas e KPIs no PostgreSQL
5. ✅ Endpoints de dashboard com métricas detalhadas
6. ✅ Frontend Flutter com exibição estruturada
7. ✅ Mascaramento LGPD + soft delete
8. ✅ Documentação + collection de testes

**Próximos passos (pós-MVP)**:
1) Capturar prints das telas para evidências finais
2) Executar smoke test com 2 `company_id` distintos
3) Validar tempo médio < 10s em staging
4) Iniciar RF2 - Cadastro e Gerenciamento de Vagas

---

# Rodada – Cadastro e Gerenciamento de Vagas (RF2)

## 1. Mike – Líder de Equipe (kickoff)

* Meta: entregar **CRUD completo de vagas (RF2)** com filtros por `company_id`, respeitando RNF2, RNF3, RNF5 e RNF6.
* Diretrizes: telas alinhadas ao Figma, integrações reais com DB e autenticação ativa.
* Ativações:

  * **Iris:** práticas de privacidade e nomenclatura de cargos.
  * **Emma:** fluxo completo de CRUD de vaga.
  * **Bob:** rotas e modelo de dados com histórico (`job_revisions`).
  * **Alex:** backend + frontend para CRUD.
  * **David:** métricas do funil de vagas.

## 2. Iris – Pesquisadora Profunda

* Recomendar taxonomia de cargos e skills para autocomplete.
* Sugerir textos neutros (sem viés) e campos mínimos obrigatórios.
* Reforçar boas práticas de não discriminação em descrições de vaga.

## 3. Emma – Gerente de Produto

* Jornada de CRUD de vaga:

  1. **Criar**: formulário para criar nova vaga (título, descrição, requisitos, salário, local, tipo de contrato).
  2. **Listar/Visualizar**: visualização em lista e/ou cards com filtros (status, área, unidade, data).
  3. **Editar**: editar vaga (manter histórico de versões relevantes — ex.: alterações em requisitos).
  4. **Excluir/Arquivar**: permitir arquivar ou excluir vaga (soft delete), preservando histórico para relatórios.
* Critérios de aceitação:

  * Formulário com validações claras (campos obrigatórios, máscaras).
  * Controle de status (rascunho, publicado, pausado, encerrado).
  * Vaga sempre vinculada a `company_id`.

## 4. Bob – Arquiteto de Software

* Backend (CRUD):

  * `POST /api/jobs` – criar vaga.
  * `GET /api/jobs` – listar vagas (filtros + paginação).
  * `GET /api/jobs/:id` – detalhes da vaga.
  * `PUT /api/jobs/:id` – atualizar vaga.
  * `DELETE /api/jobs/:id` – arquivar/excluir vaga.
* Banco:

  * `jobs(id, title, description, status, salary_min, salary_max, location, company_id, created_by, created_at, updated_at, deleted_at)`
  * `job_revisions(...)` para histórico.
* Frontend:

  * `vagas_tela.dart` com:

    * Lista de vagas (Read).
    * Form de criação/edição (Create/Update).
    * Ação de arquivar/excluir com confirmação (Delete).

## 5. Alex – Engenheiro

* Implementar migrations, repositórios e rotas CRUD para `jobs`.
* Construir telas Flutter:

  * Lista com busca, filtros.
  * Form de criação/edição com validação.
* Garantir uso de componentes reutilizáveis (inputs, selects, etc.).

## 6. David – Analista de Dados

* KPIs:

  * Vagas criadas/ativadas/encerradas por período.
  * Tempo médio de publicação.
* Views: `job_stats_overview` e `job_crud_stats`.

## 7. Mike – Fechamento

* Evidências: CRUD de vagas funcionando, filtros por `company_id` e histórico de alterações.

---

## Execução / Checkpoints (RF2)

- [ ] Rotas backend: `POST /api/jobs`, `GET /api/jobs`, `GET /api/jobs/:id`, `PUT /api/jobs/:id`, `DELETE /api/jobs/:id` (auth + `company_id` + paginação/filtros).
- [ ] Histórico de alterações: tabela `job_revisions` ou campo `version` com audit trail.
- [ ] Frontend `vagas_tela.dart`: lista com filtros (status/área/data), paginação, criação/edição, arquivar/excluir com confirmação.
- [ ] Validações: campos obrigatórios, máscaras (salário, localização), status (rascunho/publicado/pausado/encerrado).
- [ ] Banco: `jobs` com soft delete (`deleted_at`), índices em `company_id`, `status`, `created_at`; RLS por `company_id`.
- [ ] LGPD e segurança: nada de dados sensíveis; rate limiting nas rotas públicas; logs sem payload completo.
- [ ] Métricas/views: `job_stats_overview`, `job_crud_stats`.

### Próximos passos RF2
1) Implementar migrations `jobs` + `job_revisions` (ou equivalente) com RLS.
2) Criar handlers das rotas e DTOs de request/response; collection de teste.
3) Conectar `vagas_tela.dart` aos endpoints (listar/criar/editar/arquivar) com feedback de erros.
4) Capturar evidências (prints + collection + queries de métricas) e medir tempo de resposta médio por operação.

---

# Rodada – Geração de Perguntas para Entrevistas (RF3)

## 1. Mike – Líder de Equipe (kickoff)

* Objetivo: entregar serviço de geração de perguntas customizadas por vaga/candidato.
* **CRUD**: permitir **Criar**, **Listar**, **Editar** e **Excluir** conjuntos de perguntas de entrevista.
* Delegações:

  * **Iris:** prompts e mitigação de viés.
  * **Emma:** jornada CRUD de roteiros de entrevista.
  * **Bob:** contratos de API e modelo de dados.
  * **Alex:** implementação front/back.
  * **David:** métricas de uso/aderência.

## 2. Iris – Pesquisadora Profunda

* Definir boas práticas de perguntas não discriminatórias.
* Classificar perguntas por tipo (comportamental, técnica, situacional).

## 3. Emma – Gerente de Produto

* Jornada CRUD de perguntas:

  1. **Criar**: gerar perguntas automaticamente via IA para uma vaga/candidato e permitir ajustes manuais.
  2. **Listar/Visualizar**: lista de roteiros já salvos por vaga/entrevista.
  3. **Editar**: editar perguntas (texto, ordem, tipo).
  4. **Excluir**: apagar roteiros ou perguntas específicas (soft delete quando ligado a entrevistas já realizadas).
* Critérios:

  * Permitir reaproveitar roteiros entre entrevistas.
  * 5–10 perguntas por roteiro, customizáveis.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/interview-question-sets` – criar conjunto (Create).
  * `GET /api/interview-question-sets` – listar conjuntos (Read).
  * `GET /api/interview-question-sets/:id` – ver detalhes (Read).
  * `PUT /api/interview-question-sets/:id` – editar conjunto (Update).
  * `DELETE /api/interview-question-sets/:id` – excluir (Delete).
  * Rota IA específica: `POST /api/interviews/questions/generate`.
* Banco:

  * `interview_question_sets(id, job_id, resume_id, title, company_id, created_by, created_at, updated_at, deleted_at)`
  * `interview_questions(id, set_id, type, text, order, created_at)`.
* Frontend:

  * Tela/aba em `entrevistas_tela.dart` para gerenciar conjuntos com ações CRUD.

## 5. Alex – Engenheiro

* Implementar rotas CRUD e geração com IA.
* UI para:

  * Criar/gerar roteiro.
  * Ver lista de roteiros.
  * Editar (texto/ordem).
  * Excluir roteiro/perguntas.

## 6. David – Analista de Dados

* KPIs:

  * Quantidade de roteiros criados.
  * Proporção de roteiros reutilizados.
  * % de perguntas editadas vs geradas.

## 7. Mike – Fechamento

* Evidências: conjuntos criados, editados, excluídos, usados em entrevistas.

---

## Execução / Checkpoints (RF3)

- [ ] Rotas CRUD: `POST/GET/PUT/DELETE /api/interview-question-sets` + `POST /api/interviews/questions/generate` (auth + `company_id`).
- [ ] Banco: `interview_question_sets` + `interview_questions` com soft delete e índices (`company_id`, `job_id`).
- [ ] Frontend: aba/fluxo em `entrevistas_tela.dart` para criar/gerar, listar, editar (texto/ordem/tipo) e excluir roteiros.
- [ ] IA: geração de 5–10 perguntas com viés mitigado; permite edição manual antes de salvar.
- [ ] Métricas: KPIs de roteiros criados/reutilizados e % de edições pós-IA.
- [ ] Evidências: prints da aba de perguntas + collection das rotas.

### Próximos passos RF3
1) Criar migrations + repositórios + handlers das rotas.
2) Conectar UI às rotas e validar edição/ordenação.
3) Registrar evidências e KPIs iniciais.

---

# Rodada – Integração opcional com GitHub API (RF4)

## 1. Mike – Líder de Equipe (kickoff)

* Meta: complementar perfil técnico com dados do GitHub.
* **CRUD**: permitir **cadastrar**/associar username GitHub, **visualizar** dados, **atualizar** (re-sync) e **remover** integração.

## 2. Iris – Pesquisadora Profunda

* Boas práticas de privacidade e uso de dados públicos.

## 3. Emma – Gerente de Produto

* Fluxo CRUD:

  1. **Criar**: adicionar username GitHub ao perfil do candidato (opcional).
  2. **Listar/Visualizar**: ver dados coletados (linguagens, repositórios, atividade).
  3. **Atualizar**: re-sincronizar dados manualmente.
  4. **Excluir**: remover integração GitHub e limpar dados salvos, se requisitado (LGPD).
* Critérios: deixar claro que é opcional; respeitar consentimento.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/candidates/:id/github` – associar username (Create).
  * `GET /api/candidates/:id/github` – ver dados (Read).
  * `PUT /api/candidates/:id/github` – re-sync (Update).
  * `DELETE /api/candidates/:id/github` – remover e limpar (Delete).
* Banco:

  * `candidate_github_profiles(candidate_id, username, summary jsonb, last_synced_at, deleted_at)`.
* Frontend:

  * Seção “GitHub” no perfil do candidato com botões de associar, atualizar e remover.

## 5. Alex – Engenheiro

* Implementar client GitHub e rotas CRUD de integração.
* UI com formulário para username e cards para exibir dados.

## 6. David – Analista de Dados

* KPIs:

  * % candidatos com GitHub integrado.
  * Sincronizações bem-sucedidas/erro.

## 7. Mike – Fechamento

* Evidências: integrações criadas/atualizadas/removidas com sucesso.

---

## Execução / Checkpoints (RF4)

- [ ] Rotas: `POST/GET/PUT/DELETE /api/candidates/:id/github` (auth + `company_id`).
- [ ] Banco: `candidate_github_profiles` com soft delete, `last_synced_at`, índices em `candidate_id`, `company_id`.
- [ ] Client GitHub com cache/rate limit e sanitização de dados públicos.
- [ ] Frontend: seção GitHub no perfil do candidato (associar, atualizar, remover, exibir principais métricas/repos).
- [ ] LGPD: claro que é opcional; botão de remover limpa dados; logs sem payload completo.
- [ ] Métricas: % candidatos integrados, sucesso/erro de sync.
- [ ] Evidências: collection de rotas + prints da seção GitHub.

### Próximos passos RF4
1) Implementar client + rotas + persistência.
2) Ligar UI do perfil do candidato.
3) Coletar evidências e validar remoção completa dos dados.

---

# Rodada – Transcrição de Áudio da Entrevista (RF5)

## 1. Mike – Líder de Equipe (kickoff)

* Objetivo: permitir upload/gravação e transcrição de entrevistas.
* **CRUD**: permitir **cadastrar** gravações/transcrições, **listar/visualizar**, **editar anotações** e **excluir** áudio/transcrições conforme política de retenção.

## 2. Iris – Pesquisadora Profunda

* Modelos ASR, limites de tempo e boas práticas de consentimento.

## 3. Emma – Gerente de Produto

* Fluxo:

  1. **Criar**: subir ou gravar áudio de entrevista.
  2. **Listar/Visualizar**: listar gravações por entrevista, ver transcrição.
  3. **Editar**: permitir correções manuais no texto transcrito e adicionar anotações.
  4. **Excluir**: remover gravação/transcrição (por política ou pedido do candidato).
* Critérios: limite de duração/tamanho; mensagens claras.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/interviews/:id/recordings` (Create).
  * `GET /api/interviews/:id/recordings` e `GET /api/recordings/:id` (Read).
  * `PUT /api/transcripts/:id` para ajustes textuais (Update).
  * `DELETE /api/recordings/:id` e `DELETE /api/transcripts/:id` (Delete).
* Banco:

  * `interview_recordings(id, interview_id, file_path, duration, company_id, created_at, deleted_at)`
  * `interview_transcripts(id, recording_id, text, company_id, created_at, updated_at, deleted_at)`.
* Frontend:

  * Aba de gravações em `entrevistas_tela.dart` com lista de gravações, transcrição e ações CRUD.

## 5. Alex – Engenheiro

* Implementar upload/gravação e exibição das transcrições.
* Form de edição da transcrição.
* Botão de exclusão com confirmação.

## 6. David – Analista de Dados

* KPIs:

  * Número de gravações/transcrições criadas.
  * Tempo médio de transcrição.

## 7. Mike – Fechamento

* Evidências: gravações e transcrições sendo criadas, listadas, editadas e excluídas.

---

## Execução / Checkpoints (RF5)

- [ ] Rotas: `POST /api/interviews/:id/recordings`, `GET /api/interviews/:id/recordings`, `GET /api/recordings/:id`, `PUT /api/transcripts/:id`, `DELETE /api/recordings/:id`, `DELETE /api/transcripts/:id`.
- [ ] Banco: `interview_recordings`, `interview_transcripts` com RLS/`company_id`, soft delete, índices em `interview_id`, `created_at`.
- [ ] ASR/IA: pipeline de transcrição com timeout e limites de duração/tamanho; armazenar texto limpo.
- [ ] Frontend: aba de gravações em `entrevistas_tela.dart` (upload/gravação, ver transcrição, editar, excluir).
- [ ] LGPD: consentimento, retenção configurável, logs sem áudio/texto.
- [ ] Evidências: prints do fluxo + collection das rotas.

### Próximos passos RF5
1) Implementar upload + storage seguro + chamada ASR.
2) Expor transcrição/edit no frontend.
3) Validar políticas de retenção e capturar evidências.

---

# Rodada – Avaliação em Tempo Real das Respostas (RF6)

## 1. Mike – Líder de Equipe (kickoff)

* Meta: scoring em tempo real durante entrevista.
* **CRUD**: permitir **criar** registros de avaliação, **listar** avaliações por pergunta/entrevista, **ajustar manualmente** (Update) e **invalidar/excluir** avaliações equivocadas.

## 2. Iris – Pesquisadora Profunda

* Definir critérios objetivos para avaliação.

## 3. Emma – Gerente de Produto

* Fluxo:

  1. **Criar**: sistema gera avaliação automática à medida que respostas são dadas.
  2. **Listar/Visualizar**: painel que mostra avaliações por pergunta/candidato.
  3. **Editar**: entrevistador pode ajustar score e adicionar comentário.
  4. **Excluir/Invalidar**: marcar avaliação como inválida (sem apagar histórico de auditoria).
* Critérios: latência baixa, transparência quando avaliação é automática ou ajustada.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/interviews/:id/assessments` – criar avaliação (Create).
  * `GET /api/interviews/:id/assessments` – listar (Read).
  * `PUT /api/assessments/:id` – ajuste manual (Update).
  * `DELETE /api/assessments/:id` – invalidar (Delete lógico).
* Banco:

  * `live_assessments(id, interview_id, question_id, score_auto, score_manual, status, company_id, created_at, updated_at, deleted_at)`.

## 5. Alex – Engenheiro

* Implementar canal em tempo real (websocket/event-source).
* UI para ver e ajustar avaliações com ações Update/Delete.

## 6. David – Analista de Dados

* KPIs:

  * Avaliações criadas, ajustadas, invalidadas.
  * Concordância entre score automático e manual.

## 7. Mike – Fechamento

* Evidências: avaliações sendo criadas em tempo real e ajustadas pelo entrevistador.

---

## Execução / Checkpoints (RF6)

- [ ] Rotas: `POST /api/interviews/:id/assessments`, `GET /api/interviews/:id/assessments`, `PUT /api/assessments/:id`, `DELETE /api/assessments/:id` (delete lógico).
- [ ] Banco: `live_assessments` com campos auto/manual, status, RLS e índices.
- [ ] Canal tempo real (WS/SSE) para envio de avaliações e atualizações de UI.
- [ ] Frontend: painel em `entrevistas_tela.dart` mostrando avaliações ao vivo e permitindo ajuste/invalidação.
- [ ] Métricas: concordância auto x manual, quantidade de avaliações criadas/ajustadas/invalidas.
- [ ] Evidências: demo gravada/prints + collection das rotas.

### Próximos passos RF6
1) Implementar canal de eventos + persistência.
2) Conectar painel em tempo real e fluxo de ajustes.
3) Coletar evidências e KPIs básicos.

---

# Rodada – Relatórios Detalhados de Entrevistas (RF7)

## 1. Mike – Líder de Equipe (kickoff)

* Objetivo: consolidar resultados de entrevistas em relatórios exportáveis.
* **CRUD**: permitir **gerar (Criar)** relatórios, **listar/visualizar**, **atualizar/regenerar** e **remover/arquivar** relatórios antigos.

## 2. Iris – Pesquisadora Profunda

* Recomendar estrutura de relatório e cuidados de anonimização.

## 3. Emma – Gerente de Produto

* Fluxo:

  1. **Criar**: gerar relatório a partir de entrevista concluída.
  2. **Listar/Visualizar**: lista de relatórios por vaga/candidato/período.
  3. **Editar/Atualizar**: permitir regenerar relatório após ajustes em avaliações/notas.
  4. **Excluir/Arquivar**: arquivar relatórios para reduzir volume/histórico, respeitando RNF9.
* Critérios: export para PDF/CSV, filtros por vaga/período.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/interviews/:id/report` (Create).
  * `GET /api/reports` e `GET /api/reports/:id` (Read).
  * `PUT /api/reports/:id` – regenerar/atualizar (Update).
  * `DELETE /api/reports/:id` – arquivar/excluir (Delete).
* Banco:

  * `interview_reports(id, interview_id, content jsonb, format, company_id, created_at, updated_at, deleted_at)`.

## 5. Alex – Engenheiro

* Implementar geração/armazenamento/recuperação e exclusão de relatórios.
* Tela `relatorios_tela.dart` com lista, filtro e ações CRUD.

## 6. David – Analista de Dados

* KPIs:

  * Relatórios gerados por período.
  * Uso de export.

## 7. Mike – Fechamento

* Evidências: relatórios criados, visualizados, atualizados e arquivados.

---

## Execução / Checkpoints (RF7)

- [ ] Rotas: `POST /api/interviews/:id/report`, `GET /api/reports`, `GET /api/reports/:id`, `PUT /api/reports/:id`, `DELETE /api/reports/:id`.
- [ ] Banco: `interview_reports` (jsonb, format, soft delete, RLS, índices em `company_id`, `created_at`).
- [ ] Geração/export: PDF/CSV, regenerar após ajustes.
- [ ] Frontend: `relatorios_tela.dart` com lista, filtros e ações CRUD/export.
- [ ] Evidências: prints + collection + exemplo de export.

### Próximos passos RF7
1) Implementar geração/armazenamento/export no backend.
2) Conectar tela e fluxos de regenerar/arquivar.
3) Coletar evidências.

---

# Rodada – Histórico de Entrevistas (RF8)

## 1. Mike – Líder de Equipe (kickoff)

* Meta: histórico completo e filtrável de entrevistas.
* **CRUD**: entrevistas em si normalmente são criadas por fluxo de agendamento/execução; aqui focar em **Listar/Visualizar**, **Atualizar status** e **Arquivar/Excluir** entrevistas, além de criar via agendamento, se previsto.

## 2. Iris – Pesquisadora Profunda

* Regras de retenção e anonimização.

## 3. Emma – Gerente de Produto

* Fluxo:

  1. **Criar**: (se previsto) agendar e registrar nova entrevista.
  2. **Listar/Visualizar**: histórico com filtros (vaga, candidato, status, período).
  3. **Editar**: atualizar status (agendada, em andamento, concluída, cancelada) e anotações.
  4. **Excluir/Arquivar**: arquivar entrevistas antigas conforme política.
* Critérios: paginação, filtros persistentes.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/interviews` – criar entrevista (Create).
  * `GET /api/interviews` e `GET /api/interviews/:id` – listar/ver (Read).
  * `PUT /api/interviews/:id` – atualizar status/dados (Update).
  * `DELETE /api/interviews/:id` – arquivar/excluir (Delete lógico).
* Banco:

  * `interviews(id, job_id, candidate_id, status, scheduled_at, company_id, created_at, updated_at, deleted_at)`.
* Frontend:

  * `historico_tela.dart` com CRUD (quando aplicável) + filtros.

## 5. Alex – Engenheiro

* Implementar rotas CRUD e tela de histórico com ações de atualizar status e arquivar.

## 6. David – Analista de Dados

* KPIs:

  * Entrevistas criadas, concluídas, canceladas, arquivadas.
  * Tempo entre agendamento e conclusão.

## 7. Mike – Fechamento

* Evidências: histórico funcional, com filtros e ações CRUD (pelo menos Create/Read/Update + Delete lógico).

---

## Execução / Checkpoints (RF8)

- [ ] Rotas: `POST /api/interviews`, `GET /api/interviews`, `GET /api/interviews/:id`, `PUT /api/interviews/:id`, `DELETE /api/interviews/:id` (delete lógico) + filtros/paginação.
- [ ] Banco: `interviews` com RLS, soft delete, índices em `company_id`, `status`, `scheduled_at`.
- [ ] Frontend: `historico_tela.dart` com filtros (vaga/candidato/status/período), atualização de status e arquivar.
- [ ] Métricas: entrevistas criadas/concluídas/canceladas/arquivadas; tempo agendamento→conclusão.
- [ ] Evidências: prints + collection das rotas.

### Próximos passos RF8
1) Finalizar rotas/filtros + paginação.
2) Conectar tela de histórico.
3) Capturar evidências e KPIs.

---

# Rodada – Dashboard de Acompanhamento (RF9)

## 1. Mike – Líder de Equipe (kickoff)

* Objetivo: dashboard unificado com KPIs.
* **CRUD**: aqui o foco é **Read**, mas pode haver:

  * **Criar/Salvar** configurações de filtros/favoritos,
  * **Atualizar** essas preferências,
  * **Excluir** presets de dashboard salvos.

## 2. Iris – Pesquisadora Profunda

* Selecionar métricas-chave e boas práticas de visualização.

## 3. Emma – Gerente de Produto

* Fluxo:

  * Usuário acessa dashboard e visualiza dados (Read).
  * Pode salvar um conjunto de filtros/visualizações como “favorito” (Create).
  * Pode renomear/alterar favoritos (Update).
  * Pode excluir favoritos (Delete).
* Critérios: carregamento rápido, UX clara.

## 4. Bob – Arquiteto de Software

* Backend:

  * Endpoints de dados agregados (`/api/dashboard/overview`, etc.).
  * Endpoints de presets:

    * `POST /api/dashboard/presets`
    * `GET /api/dashboard/presets`
    * `PUT /api/dashboard/presets/:id`
    * `DELETE /api/dashboard/presets/:id`
* Banco:

  * `dashboard_presets(id, user_id, company_id, name, filters jsonb, created_at, updated_at, deleted_at)`.

## 5. Alex – Engenheiro

* Implementar gráficos e CRUD de presets na tela `dashboard_tela.dart`.

## 6. David – Analista de Dados

* KPIs: uso do dashboard, número de presets salvos, tempo de resposta.

## 7. Mike – Fechamento

* Evidências: dashboard com dados reais e gestão de presets (CRUD básico).

---

## Execução / Checkpoints (RF9)

- [ ] Endpoints: `/api/dashboard/overview`, `/api/dashboard/kpis` (ou similares) + CRUD de presets (`/api/dashboard/presets` ...).
- [ ] Banco: `dashboard_presets` com RLS; views agregadas para KPIs.
- [ ] Frontend: `dashboard_tela.dart` com gráficos reais e CRUD de presets/favoritos.
- [ ] Perf: tempo de carregamento rápido; cache ou materialized views se necessário.
- [ ] Evidências: prints + collection + query de KPIs.

### Próximos passos RF9
1) Implementar views/queries agregadas e presets.
2) Conectar tela e salvar/editar/excluir favoritos.
3) Registrar evidências e tempos de resposta.

---

# Rodada – Gerenciamento de Usuários (RF10)

## 1. Mike – Líder de Equipe (kickoff)

* Meta: gestão segura de usuários/roles.
* **CRUD**: **Criar usuário** (convite/cadastro), **Listar** usuários, **Editar** dados/perfil/roles e **Desativar/Excluir** usuários.

## 2. Iris – Pesquisadora Profunda

* Boas práticas de identidade (senhas, MFA, políticas de bloqueio, LGPD).

## 3. Emma – Gerente de Produto

* Fluxo:

  1. **Criar**: admin convida usuário por e-mail ou cadastra diretamente (conforme política).
  2. **Listar/Visualizar**: tela de usuários com nome, e-mail, papel, status, empresa.
  3. **Editar**: atualizar dados (nome, papel, permissões, vinculação a `company_id`).
  4. **Excluir/Desativar**: desativar usuário (soft delete), mantendo histórico de ações para RNF9.
* Critérios: UX simples; avisos claros de permissão.

## 4. Bob – Arquiteto de Software

* Backend:

  * `POST /api/users` – criar (ou convidar) usuário (Create).
  * `GET /api/users` e `GET /api/users/:id` – listar/ver (Read).
  * `PUT /api/users/:id` – atualizar dados/roles (Update).
  * `DELETE /api/users/:id` – desativar (Delete lógico).
* Banco:

  * `users(id, name, email, password_hash, status, company_id, created_at, updated_at, deleted_at)`
  * `roles`, `user_roles`, `invitations`, `password_resets`.
* Frontend:

  * `configuracoes_tela.dart` (ou similar) com CRUD de usuários e roles.

## 5. Alex – Engenheiro

* Implementar fluxos de convite, cadastro, edição de perfil e desativação.
* Garantir validação de formulário, mensagens de erro e confirmações de exclusão.

## 6. David – Analista de Dados

* KPIs:

  * Usuários ativos por empresa.
  * Convites pendentes/expirados.
  * Falhas de login.

## 7. Mike – Fechamento

* Evidências: CRUD de usuários funcionando, com trilha de auditoria e escopo por `company_id`.
