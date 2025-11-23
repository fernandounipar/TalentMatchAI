## Contextualização

O cenário atual de recrutamento e seleção é marcado por desafios crescentes na identificação de candidatos qualificados. Problemas como o grande volume de currículos para triagem manual, o tempo significativo gasto na análise de documentos e as inconsistências de informações impactam diretamente a eficiência do processo.

A **Inteligência Artificial (IA)** e os **Large Language Models (LLMs)** oferecem uma oportunidade transformadora para o RH. Nesse contexto, uma ferramenta que atue como **assistente inteligente do recrutador**, e não como substituto, surge como uma solução promissora.

---

## Objetivos

O objetivo central é desenvolver o **TalentMatchIA** para otimizar e dar suporte técnico ao recrutamento, capacitando o RH a tomar decisões mais assertivas.

A ferramenta irá:

* Analisar currículos;
* Gerar perguntas estratégicas para entrevistas;
* Fornecer relatórios objetivos durante e após as entrevistas;

sempre com o apoio da **Inteligência Artificial**.

Essa abordagem reduz a lacuna de experiência técnica entre recrutadores e candidatos, garantindo um processo seletivo mais **ágil, justo e preciso**.

---

## Proposta do Projeto

O **TalentMatchIA** será uma ferramenta **Web**, desenvolvida com tecnologias modernas, atuando como assistente inteligente do recrutador. Seu papel principal é oferecer apoio técnico especializado na:

* Análise de currículos;
* Condução de entrevistas;
* Avaliação de perfis profissionais.

Para garantir uma plataforma escalável e segura, a arquitetura técnica será baseada em:

* **Flutter Web** para o Front-End;
* **Node.js** para o Back-End;
* **PostgreSQL** como banco de dados;
* Integração com **APIs de IA**, como a OpenAI API, para processamento inteligente.

---

## Levantamento de Requisitos

### Requisitos Funcionais

* **RF1**: Upload e análise de currículos (PDF/TXT). **(MVP)**
* **RF2**: Cadastro e gerenciamento de vagas. **(MVP)**
* **RF3**: Geração de perguntas para entrevistas. **(MVP)**
* **RF4**: Integração opcional com GitHub API.
* **RF5**: Transcrição de áudio da entrevista.
* **RF6**: Avaliação em tempo real das respostas.
* **RF7**: Relatórios detalhados de entrevistas. **(MVP)**
* **RF8**: Histórico de entrevistas. **(MVP)**
* **RF9**: Dashboard de acompanhamento. **(MVP)**
* **RF10**: Gerenciamento de usuários (recrutadores/gestores). **(MVP)**

---

### Requisitos Não Funcionais

* **RNF1**: Resposta em até 10 segundos na análise de currículos. **(MVP)**
* **RNF2**: Interface simples e intuitiva para o RH. **(MVP)**
* **RNF3**: Segurança com criptografia e conformidade com LGPD/GDPR.
* **RNF4**: Disponibilidade mínima de 99,5%.
* **RNF5**: Escalabilidade para grandes volumes de dados.
* **RNF6**: Código modular e documentado. **(MVP)**
* **RNF7**: Compatibilidade com os principais navegadores.
* **RNF8**: Acurácia mínima de 85% na análise de IA.
* **RNF9**: Registro de logs para auditoria.

Vou organizar isso como um plano de implementação mesmo, já pensando no que vi no teu projeto (Flutter Web + Node.js + PostgreSQL) **e** no layout “TalentMatchIA Layout Design – Figma” (aquele projeto em React/Vite que simula o Figma).

> Foco: deixar tudo alinhado com o layout do Figma, **sem dados mockados**, só vindo do banco via API.

---

## 1. FrontEnd – Flutter Web (lib/…)

### Task FE-01 – Shell de navegação igual ao Figma

Aplicar o mesmo “esqueleto” visual do projeto Figma (Sidebar + Header + conteúdo).

* [ ] Criar um widget `AppShell` (ou equivalente) com:

  * Sidebar fixa (ícones + textos: Dashboard, Vagas, Currículos, Entrevistas, Relatórios, Configurações).
  * Header/topbar com:

    * Logo do TalentMatchIA,
    * Título da página atual,
    * Busca global (campo de pesquisa),
    * Avatar/ícone do usuário logado.
* [ ] Envolver as telas principais (`dashboard_tela.dart`, `vagas_tela.dart`, `candidatos_tela...dart`, `entrevistas_tela.dart`, `historico_tela.dart`) dentro desse `AppShell`.
* [ ] Garantir que cores, tipografia, espaçamentos usem apenas o `design_system` (`tm_colors.dart`, `tm_text.dart`) para ficar consistente com o Figma.

---

### Task FE-02 – Dashboard alinhado ao layout Figma

Deixar `dashboard_tela.dart` parecido com o `DashboardOverview` do projeto Figma.

* [ ] Criar cards de métricas principais:

  * Vagas abertas,
  * Processos em andamento,
  * Entrevistas realizadas no período,
  * Taxa de aprovação / conversão (ou outra métrica que o backend entregar).
* [ ] Implementar blocos de lista:

  * Lista de vagas recentes com status,
  * Lista de candidatos em destaque / últimos analisados.
* [ ] Conectar tudo com **endpoint real** do backend (`GET /dashboard/overview` por exemplo), sem arrays fixos na tela.
* [ ] Adicionar estados de carregamento/erro (loading spinner, mensagem de erro, etc.).

---

### Task FE-03 – Tela de Vagas seguindo o “VagasPage”

Refinar `vagas_tela.dart` com base em `VagasPage.tsx` / `VacancyManagement.tsx`.

* [ ] Layout:

  * Cabeçalho com título, botão **“Nova vaga”** e filtros (status, senioridade, palavra-chave).
  * Listagem em cards ou tabela, com colunas semelhantes ao Figma: título, nível, tipo, status, data.
* [ ] Integração:

  * Usar somente `ApiCliente.vagas()` (ou equivalente) para listar vagas, sem listas mockadas.
  * Conectar formulário de criação/edição com endpoints `POST/PUT /jobs` (ou `/vagas` – definir padrão no backend).
* [ ] Adicionar paginação/scroll infinito simples, se o backend já expuser `page/limit`.

---

### Task FE-04 – Upload & Análise de Currículo (RF1)

Ajustar `upload_curriculo_tela.dart` para ficar próximo à `CurriculosPage` + `CurriculumAnalysis` do Figma.

* [ ] Criar área de upload com:

  * Zona de “arrastar e soltar” + botão “Selecionar arquivo”,
  * Indicação de formatos suportados (PDF/TXT) e limite de tamanho.
* [ ] Após o upload:

  * Mostrar card de análise com:

    * Nome do candidato,
    * Vaga relacionada (se houver),
    * Principais skills extraídas,
    * Score/aderência à vaga (se backend retornar).
* [ ] Integração:

  * Enviar arquivo para endpoint real `POST /curriculos/upload` (ou definido no backend).
  * Exibir progresso de envio (se possível) e resultado retornado via JSON (sem nenhum dado fixo na tela).
* [ ] Tratar erros da IA/análise (mensagem amigável para o recrutador).

---

### Task FE-05 – Tela de Entrevistas & Perguntas (RF3, RF5, RF6, RF8)

Refinar `entrevistas_tela.dart` com base em `EntrevistasPage`, `InterviewQuestions` e `InterviewHistory`.

* [ ] Seções:

  * Lista de entrevistas (cards ou tabela),
  * Painel de detalhes à direita (informações do candidato + vaga),
  * Aba de perguntas geradas pela IA + respostas do candidato.
* [ ] Integração:

  * Listar entrevistas via `GET /interviews`.
  * Ao criar uma nova entrevista:

    * Selecionar vaga + candidato,
    * Chamar endpoint de geração de perguntas (`POST /interviews/{id}/perguntas` ou similar).
  * Mostrar avaliação da resposta (score, tags: pontos fortes, pontos de atenção).
* [ ] Preparar espaço/UI para futura integração de transcrição de áudio (RF5),
  mesmo que no MVP ainda seja só texto.

---

### Task FE-06 – Histórico & Relatórios (RF7, RF8, RF9)

Trabalhar `historico_tela.dart` e uma possível tela de relatórios.

* [ ] Tabela de histórico de entrevistas:

  * Filtros por vaga, candidato, período, status.
  * Colunas com data, vaga, candidato, resultado (Aprovado/Em análise/Reprovado).
* [ ] Tela/aba de Relatórios:

  * Gráficos ou cards de:

    * Tempo médio por etapa,
    * Taxa de aprovação por vaga,
    * Volume de currículos analisados.
* [ ] Integração:

  * Histórico via `GET /interviews/history` (ou similar).
  * Resumo/relatórios via endpoint `/reports/overview` ou `/dashboard/relatorios`.
* [ ] Nada de dados estáticos: tudo vem do banco.

---

### Task FE-07 – Autenticação, Usuários e Multitenant (RF10)

Ajustar login e contexto do usuário para usar o backend real.

* [ ] Garantir que `login_tela.dart` esteja usando o endpoint real de login (`POST /auth/login`), salvando:

  * access_token,
  * refresh_token,
  * dados do usuário (nome, e-mail, empresa).
* [ ] Configurar interceptors de HTTP em Flutter para:

  * anexar o token em cada requisição,
  * tentar refresh automático se o token expirar.
* [ ] Exibir no header:

  * Nome do usuário,
  * Empresa atual (company),
  * Futuro seletor de empresa (se tiver multitenant com mais de uma company por usuário).
* [ ] Garantir que as telas só exibam dados da company do usuário logado.

---

### Task FE-08 – Remoção de qualquer mock restante

Varredura geral no frontend Flutter e no projeto Figma em React.

* [ ] Remover:

  * listas estáticas de vagas/candidatos/histórico usadas só para protótipo,
  * dados de exemplo deixados em `AppState` ou `ChangeNotifier`.
* [ ] Onde precisar de dados para componentes visuais (ex.: cards do dashboard), criar endpoints específicos no backend e ajustar o Flutter para chamá-los.
* [ ] Manter o projeto React/Vite apenas como **referência visual**, sem impactar a aplicação final.

---

## 2. BackEnd – Node.js (backend/src/…)

### Task BE-01 – Consolidar modelo de domínio (Jobs vs Vagas, Candidates, etc.)

Hoje aparecem nomes como `jobs`, `vagas`, `candidates`, `applications`. É hora de consolidar.

* [ ] Definir nomenclatura oficial:

  * `jobs` = `vagas`?
  * `applications` = candidaturas do candidato à vaga?
* [ ] Ajustar:

  * Tabelas no banco (renomear se necessário),
  * Models/queries SQL nos repositórios,
  * Rotas (`/jobs`, `/candidates`, `/applications`, `/curriculos`, `/interviews`).
* [ ] Atualizar o Flutter para chamar os endpoints com os nomes finais.

---

### Task BE-02 – Fechar CRUDs principais (RF1, RF2, RF3, RF7, RF8, RF10)

Para cada recurso, garantir CRUD completo e alinhado ao front:

1. **Usuários / Autenticação**

   * [ ] `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/forgot`, `/auth/reset`.
   * [ ] `/usuarios` para gestão de usuários (apenas admins).
   * [ ] Garantir hash de senha, roles, vínculo com `company_id`.

2. **Companies (Multitenant)**

   * [ ] `/companies` – criação de empresa, associação de usuário à empresa.
   * [ ] Middleware para carregar `company_id` a partir do token.

3. **Vagas (Jobs)**

   * [ ] `/jobs` – listar, criar, atualizar, arquivar/excluir.
   * [ ] Filtros por status, senioridade, palavra-chave.

4. **Candidatos**

   * [ ] `/candidates` – CRUD básico.
   * [ ] Vínculo com currículos e candidaturas.

5. **Currículos**

   * [ ] `/curriculos/upload` – upload + criação de registro no banco.
   * [ ] `/curriculos/{id}` – detalhes e análise aplicada.

6. **Entrevistas**

   * [ ] `/interviews` – criar entrevista vinculando vaga + candidato.
   * [ ] Endpoints para geração de perguntas, registro de respostas, encerramento da entrevista.

7. **Relatórios / Dashboard**

   * [ ] `/dashboard/overview` – métricas agregadas.
   * [ ] `/reports/…` – endpoints específicos de relatório se necessário.

---

### Task BE-03 – IA Service alinhado aos requisitos (RF1, RF3, RF6, RF8)

Deixar `iaService.js` sólido e padronizado:

* [ ] Definir **contrato de entrada e saída** para:

  * `analisarCurriculo` (skills, experiência, aderência à vaga, senioridade sugerida),
  * `gerarPerguntasEntrevista` (lista de perguntas classificadas por competência),
  * `avaliarResposta` (score + observações + tags).
* [ ] Garantir que os endpoints de currículos/entrevistas chamem o `iaService` e gravem:

  * resultado estruturado em tabelas específicas (`analysis`, `interview_questions`, `interview_feedbacks` etc.).
* [ ] Tratar:

  * timeouts da OpenAI,
  * respostas inválidas,
  * logs para debugging (sem gravar dados sensíveis em log).

---

### Task BE-04 – Autenticação, segurança e multitenant (RNF3, RNF5, RNF9)

* [ ] Confirmar que o middleware de autenticação:

  * extrai `user_id` e `company_id` do token,
  * injeta isso no `req` para todas as rotas.
* [ ] Garantir que **todas as queries** usam `company_id` como filtro.
* [ ] Implementar:

  * rate limiting (já existe algo, revisar configuração),
  * logs estruturados (request ID, usuário, rota).
* [ ] Auditar dados sensíveis:

  * não retornar e-mails/senhas onde não for necessário,
  * aplicar LGPD/GDPR na devolução de dados.

---

### Task BE-05 – Integração com PostgreSQL (sem mocks)

* [ ] Remover quaisquer repositórios em memória usados só para teste.
* [ ] Garantir que todos os serviços leiam/escrevam exclusivamente no PostgreSQL (JDBC/pg-promise/knex, conforme o que você já está usando).
* [ ] Ajustar repositórios para:

  * usar transações quando criar registros em cascata (ex.: entrevista + perguntas + análise),
  * tratar erros de constraint (FKs, unique) de forma amigável.

---

### Task BE-06 – Endpoints para Dashboard e Relatórios (RF7, RF8, RF9)

* [ ] Criar funções SQL (ou views) para:

  * contagem de vagas abertas/fechadas,
  * número de entrevistas no período,
  * taxa de aprovação por vaga ou por etapa.
* [ ] Expor esses dados em endpoints:

  * `GET /dashboard/overview`,
  * `GET /dashboard/kpis` (se precisar segmentar).
* [ ] Ajustar contratos de resposta de forma simples para o Flutter consumir.

---

## 3. Banco de Dados – PostgreSQL (scripts/sql/…)

### Task DB-01 – Revisar e aplicar o schema completo

* [ ] Rodar os scripts na ordem correta (ex.: `001_schema.sql`, depois os demais de roles, multitenant, domain tables).
* [ ] Conferir se todas as tabelas necessárias para os requisitos estão presentes:

  * users, companies, jobs/vagas,
  * candidates, resumes/curriculos,
  * interviews, interview_questions, interview_answers,
  * analysis/relatorios, ingestion_jobs (se usado).
* [ ] Ajustar tipos (ex.: `UUID` para IDs, `JSONB` para campos de análise IA) conforme necessidade.

---

### Task DB-02 – Multitenant & segurança de dados

* [ ] Garantir que todos os registros possuem `company_id`.
* [ ] Configurar Row-Level Security (RLS) ou políticas equivalentes:

  * cada usuário só enxerga dados da própria empresa.
* [ ] Criar índices em:

  * `company_id`,
  * campos mais filtrados (status, vaga_id, candidate_id, created_at).

---

### Task DB-03 – Suporte ao Dashboard e Relatórios

* [ ] Criar **views** ou **materialized views** para:

  * resumo do dashboard (KPIs),
  * histórico de entrevistas,
  * taxa de conversão por vaga.
* [ ] Otimizar consultas pesadas com índices e, se necessário, agregações pré-calculadas.

---

### Task DB-04 – Dados de exemplo reais (sem mocks no código)

> Lembrando: os dados de teste podem existir **somente no banco**, nunca codificados no frontend/backend.

* [ ] Criar script de seed (ex.: `009_seed_mvp.sql`) com:

  * 1 empresa de exemplo,
  * 1–2 usuários recrutadores,
  * algumas vagas,
  * alguns candidatos + currículos,
  * algumas entrevistas concluídas.
* [ ] Usar esses dados de seed para alimentar as telas (Dashboard, Vagas, Currículos, Entrevistas, Histórico).

---

### Task DB-05 – Logs & auditoria (RNF9)

* [ ] Criar tabelas de log/auditoria (se ainda não existir):

  * login/logout,
  * ações críticas (criação de vaga, exclusão de entrevista etc.).
* [ ] Garantir que o backend grave os registros nessas tabelas.

---

## 4. Como seguir a partir daqui

Se quiser, no próximo passo eu posso:

* pegar **uma tela por vez** (por exemplo, Dashboard) e
* te entregar:

  * o contrato da API,
  * o SQL da view no Postgres,
  * o endpoint Node.js,
  * e o ajuste no Flutter (widget) já com exemplo de código.

Assim você vai fechando o ciclo **FrontEnd → BackEnd → Banco** funcional, tela por tela, sempre sem mocks.

---

## ✅ STATUS DE IMPLEMENTAÇÃO

### RF1 - Upload e Análise de Currículos
**Status:** ✅ Concluído  
**Migrations:** 012-013  
**Documentação:** Disponível

### RF2 - Cadastro e Gerenciamento de Vagas (Jobs)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 014_jobs_add_columns.sql - 13 novas colunas + job_revisions + 5 índices + 2 triggers
- ✅ 015_job_metrics_views.sql - 5 views + função get_job_metrics() + 8 índices

**API Endpoints:** 
- ✅ GET /api/jobs (listagem com 11 filtros)
- ✅ GET /api/jobs/:id (detalhes + histórico de revisões)
- ✅ POST /api/jobs (criação com auto-publish)
- ✅ PUT /api/jobs/:id (update dinâmico com versionamento)
- ✅ DELETE /api/jobs/:id (soft delete)
- ✅ GET /api/jobs/search/text (busca textual)
- ✅ GET /api/dashboard/jobs/metrics (métricas consolidadas)
- ✅ GET /api/dashboard/jobs/timeline (timeline de criação)

**Documentação:** ✅ RF2_DOCUMENTACAO.md (400+ linhas)  
**Testes:** ✅ RF2_JOBS_API_COLLECTION.http (41 requests)

**Validação:**
- ✅ Migration 014 aplicada: 25 colunas em jobs, job_revisions criada, 3 triggers ativos
- ✅ Migration 015 aplicada: 5 views funcionais, get_job_metrics() retorna 7 métricas
- ✅ Todos endpoints testados e documentados

---

### RF3 - Geração de Perguntas para Entrevistas (Interview Question Sets)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 016_interview_question_sets.sql - Tabela interview_question_sets (12 colunas) + 6 colunas novas em interview_questions (set_id, type, text, order, updated_at, deleted_at) + 5 índices + 2 triggers
- ✅ 017_question_metrics_views.sql - 5 views (question_sets_stats, question_sets_by_job, question_type_distribution, question_sets_usage, question_editing_stats) + função get_question_set_metrics() + 2 índices adicionais

**API Endpoints:**
- ✅ GET /api/interview-question-sets (listagem com filtros por job_id, is_template, busca textual, ordenação)
- ✅ GET /api/interview-question-sets/:id (detalhes completos + perguntas ordenadas)
- ✅ POST /api/interview-question-sets (criação manual OU via IA com generate_via_ai: true)
- ✅ PUT /api/interview-question-sets/:id (update de metadados + edição/adição de perguntas)
- ✅ DELETE /api/interview-question-sets/:id (soft delete de conjunto + perguntas não usadas)
- ✅ DELETE /api/interview-question-sets/:setId/questions/:questionId (soft delete de pergunta específica)
- ✅ GET /api/dashboard/question-sets/metrics (métricas consolidadas: 6 métricas + distribuição por tipo + top 5 sets)
- ✅ GET /api/dashboard/question-sets/editing-stats (estatísticas de IA vs Manual vs Edited)
- ✅ GET /api/dashboard/question-sets/by-job (conjuntos agrupados por vaga com breakdown de tipos)

**Documentação:** ✅ RF3_DOCUMENTACAO.md (completa com exemplos, troubleshooting, boas práticas)  
**Testes:** ✅ RF3_QUESTIONS_API_COLLECTION.http (50+ requests cobrindo CRUD, métricas, validações, segurança, performance, E2E)

**Validação:**
- ✅ Migration 016 aplicada: interview_question_sets com 12 colunas, interview_questions com 6 novas colunas, 5 índices, 2 triggers
- ✅ Migration 017 aplicada: 5 views criadas, get_question_set_metrics() retorna 6 métricas, 2 índices adicionais
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **interview_question_sets:** Conjuntos de perguntas (templates ou específicos de vaga/candidato)
- **interview_questions:** Perguntas individuais com categorização (behavioral, technical, situational, cultural, general), ordenação, origem (ai_generated, manual, ai_edited)
- **Integração IA:** openRouterService.gerarPerguntasEntrevista(vaga, curriculo) para geração automática
- **Soft Delete:** Preserva perguntas usadas em entrevistas, permite deletar apenas não-usadas
- **Multitenant:** Isolamento por company_id em todas as queries

**Features:**
- Criação manual de conjuntos com perguntas customizadas
- Geração automática via IA baseada em vaga (com ou sem currículo do candidato)
- Templates reutilizáveis (is_template: true)
- Edição de perguntas (texto, tipo, ordem) com tracking de origem
- Métricas: uso de conjuntos, distribuição por tipo, % IA vs manual, top conjuntos mais usados
- Filtros avançados: por vaga, template, busca textual, ordenação por data/título
- Paginação: 20 itens default, max 100

---

### RF6 - Avaliação em Tempo Real das Respostas (Live Assessments)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 018_live_assessments.sql - Tabela live_assessments (19 colunas) + 6 índices + 1 trigger + 1 função
- ✅ 019_assessment_metrics_views.sql - 5 views + função get_assessment_metrics() + 2 índices adicionais

**API Endpoints:**
- ✅ POST /api/live-assessments (criação automática via IA ou manual)
- ✅ GET /api/live-assessments (listagem com 7 filtros: interview_id, status, type, sort, page, limit)
- ✅ GET /api/live-assessments/:id (detalhes completos com contexto)
- ✅ PUT /api/live-assessments/:id (ajuste manual de score/feedback)
- ✅ DELETE /api/live-assessments/:id (soft delete/invalidar)
- ✅ GET /api/live-assessments/interview/:interview_id (todas avaliações de uma entrevista + stats)
- ✅ GET /api/dashboard/assessments/metrics (métricas consolidadas: 8 métricas + distribuição + concordância)
- ✅ GET /api/dashboard/assessments/timeline (timeline diária de avaliações)
- ✅ GET /api/dashboard/assessments/by-interview (últimas 50 entrevistas com stats)

**Documentação:** ✅ RF6_DOCUMENTACAO.md (completa com exemplos, fluxos, troubleshooting)  
**Testes:** ✅ RF6_ASSESSMENTS_API_COLLECTION.http (45+ requests cobrindo CRUD, métricas, validações, performance, E2E)

**Validação:**
- ✅ Migration 018 aplicada: live_assessments com 19 colunas, 8 índices, 1 trigger (update_live_assessments_timestamps), 1 função, 11 constraints
- ✅ Migration 019 aplicada: 5 views funcionais, get_assessment_metrics() retorna 8 métricas, 2 índices adicionais
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **live_assessments:** Sistema de avaliação dual (IA + humano) com score_auto, score_manual, score_final (calculado automaticamente via trigger)
- **Feedback estruturado:** feedback_auto (JSONB: {nota, feedback, pontosFortesResposta, pontosMelhoria}), feedback_manual (TEXT)
- **Categorização:** assessment_type (behavioral, technical, situational, cultural, general)
- **Status:** pending → auto_evaluated → manually_adjusted → validated/invalidated
- **Integração IA:** openRouterService.avaliarResposta(pergunta, resposta) para avaliação automática
- **Soft Delete:** Preserva histórico de auditoria (deleted_at + status='invalidated')
- **Multitenant:** Isolamento por company_id em todas as queries

**Features:**
- Criação automática com avaliação via IA (auto_evaluate: true)
- Criação manual sem IA (auto_evaluate: false)
- Input flexível: question_id/answer_id OU question_text/answer_text
- Ajuste manual de scores pelo recrutador com tracking de quem/quando ajustou
- Métricas de concordância IA vs humano (diferença <= 1 ponto = concordante)
- Timeline de performance diária
- Tempo de resposta do candidato (response_time_seconds)
- Estatísticas por entrevista (total, média, min/max scores)
- Filtros avançados: por entrevista, status, tipo, ordenação customizada
- Paginação: 20 itens default, max 100

**Casos de Uso:**
1. **Durante entrevista:** Candidato responde → Sistema avalia via IA → Recrutador vê score em tempo real
2. **Ajuste manual:** Recrutador revisa avaliações → Ajusta score/feedback → Sistema recalcula score_final automaticamente
3. **Análise de qualidade:** Dashboard mostra concordância IA vs humano → Identifica padrões → Ajusta prompts da IA

---

### RF7 - Relatórios Detalhados de Entrevistas (Interview Reports)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 020_interview_reports.sql - Tabela interview_reports (26 colunas) + 8 índices + 1 trigger + 1 função
- ✅ 021_report_metrics_views.sql - 5 views + função get_report_metrics() + 2 índices adicionais

**API Endpoints:**
- ✅ POST /api/reports (criação automática via IA ou manual)
- ✅ GET /api/reports (listagem com 11 filtros: interview_id, type, recommendation, is_final, format, date, search, sort, page, limit)
- ✅ GET /api/reports/:id (detalhes completos com usuários)
- ✅ PUT /api/reports/:id (atualizar campos OU regenerar nova versão)
- ✅ DELETE /api/reports/:id (soft delete/arquivar)
- ✅ GET /api/reports/interview/:interview_id (todos os relatórios de uma entrevista + stats)
- ✅ GET /api/dashboard/reports/metrics (métricas consolidadas: 10 métricas + distribuição por tipo/recomendação)
- ✅ GET /api/dashboard/reports/timeline (timeline diária de geração)
- ✅ GET /api/dashboard/reports/by-interview (últimas 50 entrevistas com stats de relatórios)

**Documentação:** ✅ RF7_DOCUMENTACAO.md (completa com exemplos, integração IA, fluxos)  
**Testes:** ✅ RF7_REPORTS_API_COLLECTION.http (42 requests cobrindo CRUD, métricas, validações, performance, E2E)

**Validação:**
- ✅ Migration 020 aplicada: interview_reports com 26 colunas, 10 índices, 1 trigger (update_interview_reports_timestamps), 1 função, 16 constraints
- ✅ Migration 021 aplicada: 5 views funcionais, get_report_metrics() retorna 10 métricas, 2 índices adicionais
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **interview_reports:** Sistema de geração e versionamento de relatórios (automático IA ou manual)
- **Conteúdo estruturado:** content (JSONB flexível), summary_text, candidate_name, job_title
- **Avaliação:** overall_score (0-10), recommendation (APPROVE, MAYBE, REJECT, PENDING)
- **Análise:** strengths (pontos fortes), weaknesses (pontos fracos), risks (riscos identificados)
- **Tipos:** report_type (full, summary, technical, behavioral)
- **Formatos:** format (json, pdf, html, markdown)
- **Versionamento:** version (incrementa a cada regeneração), is_final (indica versão final)
- **Integração IA:** iaService.gerarRelatorioEntrevista(candidato, vaga, respostas, feedbacks)
- **Soft Delete:** Preserva histórico completo (deleted_at)
- **Multitenant:** Isolamento por company_id em todas as queries

**Features:**
- Geração automática via IA baseada em respostas + avaliações (live_assessments)
- Criação manual sem IA (customização total)
- Versionamento automático (regenerar cria v2, v3... preservando histórico)
- Múltiplos tipos de relatório (completo, resumo, técnico, comportamental)
- Múltiplos formatos (JSON, PDF, HTML, Markdown)
- Métricas: taxa de aprovação/rejeição, scores médios, volume por período
- Timeline de geração (estatísticas diárias)
- Estatísticas por entrevista (total de versões, score final, recomendação)
- Busca textual (título, resumo, nome do candidato, título da vaga)
- Filtros avançados: por entrevista, tipo, recomendação, final/rascunho, formato, período
- Paginação: 20 itens default, max 100

**Casos de Uso:**
1. **Após entrevista:** Sistema gera relatório automático via IA → Analisa respostas + avaliações → Cria rascunho
2. **Revisão recrutador:** Recrutador ajusta score/recomendação → Adiciona observações → Marca como final
3. **Regeneração:** Avaliações atualizadas → Recrutador regenera relatório → Sistema cria nova versão preservando histórico
4. **Análise de métricas:** Dashboard mostra taxa de aprovação → Identifica padrões → Timeline mostra volume temporal

**Integração com RF6:**
- Busca avaliações (live_assessments) da entrevista
- Extrai scores, feedbacks_auto, feedbacks_manual
- Usa como input para iaService.gerarRelatorioEntrevista()
- Consolida em relatório único estruturado

---

### RF8 - Histórico de Entrevistas (Interview History)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 022_interviews_improvements.sql - Adiciona 11 colunas à tabela interviews (notes, duration_minutes, completed_at, cancelled_at, cancellation_reason, interviewer_id, result, overall_score, metadata, updated_at, deleted_at) + 1 FK (interviewer_id → users) + constraint status atualizado (5 valores: scheduled/in_progress/completed/cancelled/no_show) + 9 índices + 1 trigger (update_interviews_timestamps com auto-fill de completed_at/cancelled_at)
- ✅ 023_interview_metrics_views.sql - 7 views (interview_stats_overview, interviews_by_status, interviews_by_result, interview_timeline, interviews_by_job, interviews_by_interviewer, interview_completion_rate) + função get_interview_metrics() + 3 índices adicionais

**API Endpoints:**
- ✅ GET /api/interviews (listagem com 10 filtros: status, result, mode, job_id, candidate_id, interviewer_id, from, to, page, limit)
- ✅ GET /api/interviews/:id (detalhes completos com interviewer_name)
- ✅ POST /api/interviews (criação com interviewer_id, notes, metadata)
- ✅ PUT /api/interviews/:id (update dinâmico com result, overall_score, notes, duration_minutes, cancellation_reason, interviewer_id, metadata, trigger auto-preenche completed_at/cancelled_at)
- ✅ DELETE /api/interviews/:id (soft delete)
- ✅ GET /api/dashboard/interviews/metrics (métricas consolidadas: 14 KPIs + distribuição por status + distribuição por resultado)
- ✅ GET /api/dashboard/interviews/timeline (timeline diária: criadas, scheduled, completed, cancelled, approved, rejected, avg_score, avg_duration)
- ✅ GET /api/dashboard/interviews/by-job (entrevistas por vaga: total, completed, approved, rejected, avg_score)
- ✅ GET /api/dashboard/interviews/by-interviewer (entrevistas por entrevistador: total, completed, approved, avg_score, avg_duration)
- ✅ GET /api/dashboard/interviews/completion-rate (taxa de conclusão diária: total_scheduled, completed, cancelled, no_show, completion_rate, no_show_rate)

**Documentação:** ✅ RF8_DOCUMENTACAO.md (completa com status lifecycle, exemplos, integração com RF2/RF3/RF6/RF7)  
**Testes:** ✅ RF8_INTERVIEWS_API_COLLECTION.http (70+ requests cobrindo CRUD, filtros, dashboard, validações, segurança, performance, E2E)

**Validação:**
- ✅ Migration 022 aplicada: interviews com 18 colunas (7 originais + 11 RF8), 1 FK (interviewer_id → users), constraint status atualizado (5 valores), 12 índices, 1 trigger (trigger_update_interviews) ativo
- ✅ Migration 023 aplicada: 7 views funcionais, get_interview_metrics() retorna 14 métricas, 3 índices adicionais
- ✅ Conversão PT→EN: Migration 022 converte status antigos (PENDENTE→scheduled, EM_ANDAMENTO→in_progress, CONCLUIDA→completed, CANCELADA→cancelled)
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **interviews (enhanced):** 18 colunas total (7 originais + 11 RF8)
- **Novos campos RF8:**
  * notes (TEXT): Observações do entrevistador
  * duration_minutes (INTEGER): Duração real
  * completed_at (TIMESTAMP): Auto-preenchido ao concluir (trigger)
  * cancelled_at (TIMESTAMP): Auto-preenchido ao cancelar (trigger)
  * cancellation_reason (TEXT): Motivo do cancelamento
  * interviewer_id (UUID FK→users): Entrevistador responsável
  * result (TEXT CHECK: approved/rejected/pending/on_hold): Decisão final
  * overall_score (NUMERIC 4,2 CHECK: 0-10): Score geral
  * metadata (JSONB): Dados adicionais (meet link, recording, etc)
  * updated_at (TIMESTAMP): Última atualização (auto-update via trigger)
  * deleted_at (TIMESTAMP): Soft delete
- **Status lifecycle:** scheduled → in_progress → completed/cancelled/no_show
- **Result tracking:** approved/rejected/pending/on_hold (separado de status)
- **Trigger auto-fill:** Ao mudar status para 'completed', preenche completed_at; ao mudar para 'cancelled', preenche cancelled_at
- **Soft Delete:** deleted_at preserva histórico, filtro WHERE deleted_at IS NULL em listagens
- **Multitenant:** Isolamento por company_id em todas as queries

**Features:**
- CRUD completo com suporte aos 11 novos campos RF8
- Filtros avançados: status, result, mode, interviewer_id, job_id, candidate_id, período (from/to)
- Soft delete preserva histórico completo
- Atribuição de entrevistador (interviewer_id) para tracking de workload
- Registro de resultado (approved/rejected/pending/on_hold) separado de status
- Score geral da entrevista (0-10) com constraint
- Duração real em minutos para análise de tempo
- Notas/observações do entrevistador para contexto
- Metadata JSONB para campos customizados (meet link, location, etc)
- Trigger automático para timestamps (updated_at, completed_at, cancelled_at)
- Dashboard com 5 endpoints de métricas:
  * Métricas consolidadas (14 KPIs incluindo approval_rate, rejection_rate, avg_score, avg_duration)
  * Timeline diária (volume de criação, conclusão, cancelamento ao longo do tempo)
  * Entrevistas por vaga (comparação de performance de recrutamento)
  * Entrevistas por entrevistador (workload e performance individual)
  * Taxa de conclusão (scheduled vs completed vs cancelled vs no_show)
- 7 views de métricas para agregações eficientes
- Paginação: 50 itens default, max 50

**Casos de Uso:**
1. **Agendar entrevista:** Recrutador seleciona vaga + candidato → Define horário, modo (online/presencial), entrevistador → Sistema cria application (se não existir) + interview + calendar_event
2. **Conduzir entrevista:** Entrevistador lista entrevistas do dia → Inicia (status=in_progress) → Durante: faz perguntas, registra respostas, sistema avalia (RF6) → Conclui (status=completed, result, score, duration, notes)
3. **Analisar performance:** Gestor acessa dashboard → Visualiza KPIs (total, aprovação%, rejeição%, scores) → Analisa timeline (tendências temporais) → Compara vagas (qual vaga tem melhor taxa?) → Avalia entrevistadores (quem tem mais aprovações?) → Identifica gargalos (no-show rate alto?)
4. **Cancelar entrevista:** Recrutador/candidato cancela → Define cancellation_reason → Sistema marca cancelled_at automaticamente (trigger) → Opcional: notificação

**Integração com Outros RFs:**
- **RF2 (Jobs):** interviews.application_id → applications.job_id → jobs.id; view interviews_by_job agrega por vaga
- **RF3 (Questions):** interviews.id ← interview_questions.interview_id; perguntas geradas para entrevista
- **RF6 (Assessments):** interviews.id ← live_assessments.interview_id; overall_score pode ser média dos assessments
- **RF7 (Reports):** interviews.id ← interview_reports.interview_id; relatório final gerado ao concluir

**Diferenças vs RF7:**
- RF7: Criou nova tabela (interview_reports) do zero
- RF8: Melhorou tabela existente (interviews) com 11 novas colunas
- interviews.js já tinha CRUD básico → RF8 expandiu com novos campos e filtros

---

### RF10 - Gerenciamento de Usuários (User Management)
**Status:** ✅ Concluído  
**Data:** 22/11/2025  
**Migrations:**
- ✅ 024_users_improvements.sql - Adiciona 14 colunas à tabela users (phone, department, job_title, last_login_at, last_login_ip, failed_login_attempts, locked_until, email_verified, email_verified_at, invitation_token, invitation_expires_at, invited_by, bio, preferences) + 2 triggers (update_users_timestamps, check_and_lock_user_account) + 8 índices + 1 FK (invited_by → users) + 1 view (active_users_overview) + data migration (cargo → job_title, existing users marked as email_verified=TRUE)
- ✅ 025_user_metrics_views.sql - 7 views (user_stats_overview, users_by_role, users_by_department, user_login_timeline, user_registration_timeline, user_security_stats, user_invitation_stats) + função get_user_metrics() + 3 índices adicionais

**API Endpoints:**
- ✅ POST /api/usuarios (criar usuário diretamente com senha)
- ✅ POST /api/usuarios/invite (convidar usuário com token temporário)
- ✅ POST /api/usuarios/accept-invite (aceitar convite e definir senha - rota pública)
- ✅ GET /api/usuarios (listar usuários com 9 filtros: role, department, is_active, email_verified, search, sort, order, page, limit)
- ✅ GET /api/usuarios/:id (detalhes completos do usuário com company_name, invited_by_name)
- ✅ PUT /api/usuarios/:id (update dinâmico de qualquer campo incluindo password, role, preferences)
- ✅ DELETE /api/usuarios/:id (soft delete com proteção contra auto-delete)
- ✅ GET /api/dashboard/users/metrics (métricas consolidadas: 17 KPIs incluindo active_rate, verification_rate)
- ✅ GET /api/dashboard/users/by-role (distribuição por role com activity metrics)
- ✅ GET /api/dashboard/users/by-department (distribuição por departamento)
- ✅ GET /api/dashboard/users/login-timeline (timeline diária de logins únicos + total)
- ✅ GET /api/dashboard/users/registration-timeline (timeline diária de registros + verified)
- ✅ GET /api/dashboard/users/security-stats (7 métricas de segurança: failed attempts, locked, unverified)
- ✅ GET /api/dashboard/users/invitation-stats (4 métricas: total, pending, expired, accepted)

**Documentação:** ✅ RF10_DOCUMENTACAO.md (completa com estrutura de banco, API endpoints, segurança, fluxos, troubleshooting)  
**Testes:** ✅ RF10_USERS_API_COLLECTION.http (70 requests cobrindo CRUD, invitation flow, filtros, dashboard, segurança, edge cases)

**Validação:**
- ✅ Migration 024 aplicada: users com 26 colunas (12 originais + 14 RF10), 1 FK (invited_by → users), constraint role atualizado (4 valores), 11 índices, 3 triggers (trg_users_updated, trigger_check_lock_account, trigger_update_users) ativos
- ✅ Migration 025 aplicada: 7 views funcionais, get_user_metrics() retorna 17 métricas, 3 índices adicionais
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **users (enhanced):** 26 colunas total (12 originais + 14 RF10)
- **Novos campos RF10:**
  * **phone** (VARCHAR 20): Telefone de contato
  * **department** (VARCHAR 100): Departamento do usuário
  * **job_title** (VARCHAR 150): Cargo (substituiu cargo via data migration)
  * **last_login_at** (TIMESTAMP): Timestamp do último login para tracking de atividade
  * **last_login_ip** (VARCHAR 45): IP do último login (IPv4/IPv6) para segurança
  * **failed_login_attempts** (INTEGER DEFAULT 0): Contador de tentativas falhas para bloqueio
  * **locked_until** (TIMESTAMP): Timestamp até quando conta está bloqueada (auto-set por trigger)
  * **email_verified** (BOOLEAN DEFAULT FALSE): Status de verificação de email
  * **email_verified_at** (TIMESTAMP): Quando email foi verificado
  * **invitation_token** (VARCHAR 255): Token único para convite temporário
  * **invitation_expires_at** (TIMESTAMP): Expiração do convite (7 dias default)
  * **invited_by** (UUID FK→users): Quem convidou este usuário (invitation graph)
  * **bio** (TEXT): Biografia/notas do usuário
  * **preferences** (JSONB DEFAULT '{}'): Preferências flexíveis (language, theme, notifications, etc)
- **Data Migration:** UPDATE users SET job_title = cargo WHERE cargo IS NOT NULL; marca existing users como email_verified=TRUE retroativamente
- **Updated Constraint:** role CHECK IN ('USER', 'RECRUITER', 'ADMIN', 'SUPER_ADMIN') - 4 valores padronizados
- **Foreign Key:** invited_by → users(id) ON DELETE SET NULL (preserva histórico se convidador deletado)
- **Triggers (2 novos RF10):**
  * **update_users_timestamps()** BEFORE UPDATE: Auto-atualiza updated_at = NOW() em qualquer alteração
  * **check_and_lock_user_account()** BEFORE UPDATE OF failed_login_attempts: Auto-bloqueia conta (locked_until = NOW() + 15 min) quando failed_login_attempts >= 5 (previne brute-force)
- **Soft Delete:** deleted_at preserva histórico de auditoria completo
- **Multitenant:** Isolamento estrito por company_id em todas as queries

**Features:**
- CRUD completo com suporte aos 14 novos campos RF10
- Sistema de convites com token temporário (expires_in_days configurável, default 7 dias)
- Aceitação de convite pública (sem auth) com definição de senha e preferences
- Bloqueio automático de conta após 5 tentativas falhas (15 min de bloqueio via trigger)
- Rastreamento de login (timestamp + IP) para auditoria de segurança
- Verificação de email com tracking de quando foi verificado
- Atribuição de department e job_title para organização
- Preferences JSONB para settings customizáveis sem schema changes
- Atualização dinâmica (envia apenas campos que deseja alterar)
- Redefinição de senha reseta automaticamente failed_login_attempts e locked_until
- Invitation graph (invited_by FK) rastreia cadeia de convites
- Filtros avançados: role, department, is_active, email_verified, search (nome/email/dept/job), sort por múltiplos campos
- Dashboard com 7 endpoints de métricas:
  * Métricas consolidadas (17 KPIs: total, active, inactive, verified, unverified, por role, locked, activity 7/30 dias, pending invites, active_rate%, verification_rate%)
  * Distribuição por role (counts, active, verified, most_recent_login)
  * Distribuição por department (counts, active)
  * Timeline de login (daily unique users logged + total logins)
  * Timeline de registro (daily registrations + active + verified)
  * Security stats (7 métricas: total, with_failed_attempts, currently_locked, avg/max attempts, unverified, unverified%)
  * Invitation stats (4 métricas: total, pending, expired, accepted)
- Paginação: 50 itens default, max 100
- Soft delete com proteção contra auto-delete
- Auditoria completa de ações (create, invite, update, delete)

**Casos de Uso:**
1. **Criar usuário diretamente:** Admin cria usuário com senha → Usuário faz login imediatamente
2. **Convidar usuário:** Admin envia convite (token gerado) → TODO: Email com link → Usuário aceita convite → Define senha → Marca email_verified=TRUE automaticamente → Usuário faz login
3. **Bloqueio automático:** 5 logins falhos → Trigger bloqueia conta por 15 min → Admin pode desbloquear via PUT com nova senha
4. **Rastreamento de atividade:** Dashboard mostra login timeline → Identifica usuários inativos → Analisa padrões de uso
5. **Gerenciar roles:** Promover USER → RECRUITER → ADMIN via PUT /usuarios/:id → Auditoria rastreia mudanças
6. **Analisar segurança:** Security stats mostra contas bloqueadas + unverified → Admin toma ações preventivas

**Integração com Outros RFs:**
- **RF1-RF8:** users.id como creator/updater de recursos (resumes, jobs, questions, assessments, reports, interviews)
- **RF2 (Jobs):** jobs.created_by → users.id; dashboard mostra vagas criadas por usuário
- **RF8 (Interviews):** interviews.interviewer_id → users.id; dashboard mostra entrevistas por entrevistador
- **Invitation Graph:** invited_by FK cria árvore de convites para análise de recrutamento

**Diferenças vs Outros RFs:**
- RF10: Melhora tabela crítica existente (users) que afeta autenticação/autorização de todo o sistema
- Adiciona 14 colunas vs criar nova tabela (outros RFs criaram tabelas novas)
- Dois arquivos de rotas: user.js (self-service, já existia) + usuarios.js (admin CRUD, expandido)
- Feature única: Sistema de convites com token temporário (não presente em outros RFs)
- Triggers de segurança: Auto-bloqueio após 5 tentativas (crítico para prevenção de ataques)

---

### RF9 - Dashboard de Acompanhamento (Dashboard Overview & Presets)
**Status:** ✅ Concluído  
**Data:** 22/01/2025  
**Migrations:**
- ✅ 026_dashboard_presets.sql - Tabela dashboard_presets (16 colunas) + 8 índices + 1 trigger + 1 view (dashboard_presets_overview)
- ✅ 027_dashboard_metrics_views.sql - 5 views (dashboard_global_overview, dashboard_activity_timeline, dashboard_preset_usage_stats, dashboard_top_presets, dashboard_conversion_funnel) + função get_dashboard_overview() + 3 índices adicionais

**API Endpoints:**
- ✅ GET /api/dashboard/overview (overview consolidado: 26+ métricas em 1 chamada via get_dashboard_overview function)
- ✅ GET /api/dashboard/activity-timeline (timeline diária de atividades com 7 métricas: jobs_created, resumes_uploaded, interviews_scheduled, reports_generated, users_registered, total_activities, filtro por days)
- ✅ GET /api/dashboard/conversion-funnel (funil de conversão por vaga com 8 métricas + 2 taxas calculadas: total_resumes, total_interviews, completed_interviews, approved_candidates, resume_to_interview_rate, interview_to_approval_rate, filtros por status, sort, limit)
- ✅ POST /api/dashboard/presets (criar preset: salvar configuração customizada de dashboard com filters/layout/preferences JSONB, is_default auto-desmarca outros, validação de nome obrigatório)
- ✅ GET /api/dashboard/presets (listar presets: próprios + compartilhados com role do usuário, filtros por search/is_shared/is_default, ordenação por usage_count/last_used_at/created_at/name, paginação 20/100)
- ✅ GET /api/dashboard/presets/:id (buscar preset: incrementa usage_count + atualiza last_used_at, retorna detalhes com user_name/company_name, verificação de acesso: dono OU shared com role)
- ✅ PUT /api/dashboard/presets/:id (atualizar preset: update dinâmico de qualquer campo, apenas dono pode editar, is_default auto-desmarca outros, validação de pelo menos 1 campo)
- ✅ DELETE /api/dashboard/presets/:id (soft delete de preset: apenas dono pode deletar, preserva auditoria)

**Documentação:** ✅ RF9_DOCUMENTACAO.md (completa com estrutura de banco, fluxos, troubleshooting, boas práticas)  
**Testes:** ✅ RF9_DASHBOARD_API_COLLECTION.http (57 requests cobrindo overview, timeline, funil, CRUD presets, E2E, segurança, performance)

**Validação:**
- ✅ Migration 026 aplicada: dashboard_presets com 16 colunas, 2 FKs (user_id, company_id), 8 índices (user_company, default, shared, GIN search, GIN filters, usage ranking), 1 trigger (update_dashboard_presets_timestamps), 1 view (dashboard_presets_overview), 2 constraints (name_not_empty, usage_count_positive)
- ✅ Migration 027 aplicada: 5 views funcionais (global_overview com 13 métricas, activity_timeline com 7 métricas diárias, preset_usage_stats com 11 métricas, top_presets com ranking, conversion_funnel com 8 métricas + 2 taxas), get_dashboard_overview() retorna JSON com 3 seções (global, presets, conversion), 3 índices adicionais (jobs/resumes/interviews company_created_date)
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **dashboard_presets:** Configurações customizadas de dashboard (16 colunas):
  * **id, user_id, company_id, name, description** - Identificação e ownership
  * **filters** (JSONB): Filtros aplicados (período, status, department, etc) - Flexível sem schema changes
  * **layout** (JSONB): Layout de widgets e ordenação (widgets array, order, grid config)
  * **preferences** (JSONB): Preferências visuais (theme, chartType, showLegends, autoRefresh, etc)
  * **is_default** (BOOLEAN): Se TRUE, carrega automaticamente ao acessar dashboard (apenas 1 por usuário via lógica de desmarcação)
  * **is_shared** (BOOLEAN): Se TRUE, outros usuários podem ver
  * **shared_with_roles** (TEXT[]): Roles com acesso (ex: ['ADMIN', 'RECRUITER'])
  * **usage_count** (INTEGER): Contador de uso (incrementa ao acessar GET /:id)
  * **last_used_at** (TIMESTAMP): Última vez que foi usado
  * **created_at, updated_at, deleted_at** - Auditoria completa
- **5 Views de Métricas:**
  * **dashboard_global_overview**: 13 métricas consolidadas (total_jobs, active_jobs, total_resumes, total_candidates, total_interviews, completed_interviews, total_reports, total_users, active_users, jobs_last_7_days, resumes_last_7_days, interviews_last_7_days, last_activity_at)
  * **dashboard_activity_timeline**: Timeline diária com 7 métricas por data (jobs_created, resumes_uploaded, interviews_scheduled, reports_generated, users_registered, total_activities, activity_date)
  * **dashboard_preset_usage_stats**: 11 métricas de uso de presets (total_presets, default_presets, shared_presets, users_with_presets, total_usage, avg_usage_per_preset, max_usage, used_last_7_days, used_last_30_days, most_recent_usage, most_recent_creation)
  * **dashboard_top_presets**: Ranking de presets por uso (com ROW_NUMBER particionado por company, usage_rank)
  * **dashboard_conversion_funnel**: Funil de conversão por vaga (8 métricas + 2 taxas: job_id, job_title, job_status, job_created_at, total_resumes, total_interviews, completed_interviews, approved_candidates, resume_to_interview_rate, interview_to_approval_rate)
- **Função get_dashboard_overview()**: Retorna JSON com 26+ métricas em 3 seções (global: 13, presets: 8, conversion: 5)
- **Índices (11 total):** 8 em dashboard_presets (user_company, company, default, shared, GIN search, GIN filters, usage ranking, created_at) + 3 adicionais (jobs/resumes/interviews company_created_date)
- **Soft Delete:** deleted_at preserva histórico de auditoria
- **Multitenant:** Isolamento estrito por company_id em todas as queries

**Features:**
- Overview consolidado com 26+ KPIs de todos os módulos em 1 chamada (performance otimizada)
- Activity timeline: rastreamento diário de criação de recursos ao longo do tempo (jobs, resumes, interviews, reports, users)
- Conversion funnel: análise de taxas de conversão (vagas → currículos → entrevistas → aprovações com percentuais calculados)
- Presets customizáveis: salvar configurações de dashboard com filtros, layout, preferências em JSONB flexível
- Sistema de sharing: compartilhar presets com roles específicos (is_shared + shared_with_roles array)
- Tracking de uso: usage_count + last_used_at para analytics de adoção (identificar presets populares)
- Default preset: marcar 1 preset como default para carregar automaticamente (auto-desmarcação de outros)
- Busca textual: full-text search em nome + descrição via GIN index
- Filtros avançados: por search, is_shared, is_default, ordenação por usage_count/last_used_at/created_at/name
- CRUD completo com validações (nome obrigatório, ownership check, soft delete)
- Paginação: 20 itens default, max 100
- Performance: 11 índices otimizados + 5 views agregadas para queries rápidas

**Casos de Uso:**
1. **Carregar dashboard inicial:** Frontend faz GET /overview → Recebe 26+ métricas consolidadas → Renderiza KPI cards → GET /presets?is_default=true → Aplica filtros/layout salvos
2. **Salvar configuração customizada:** Usuário ajusta filtros (período, status) + layout (widgets, ordem) + preferências (tema, gráficos) → POST /presets com JSONB → Sistema salva configuração reutilizável
3. **Compartilhar dashboard com equipe:** Usuário cria preset pessoal → Refina configuração → PUT com is_shared=true + shared_with_roles=['ADMIN','RECRUITER'] → Outros usuários veem na listagem e aplicam mesma configuração
4. **Analisar tendências:** GET /activity-timeline?days=30 → Visualiza timeline de atividades diárias → Identifica picos/vales → Compara períodos (7 vs 30 vs 90 dias)
5. **Identificar gargalos no funil:** GET /conversion-funnel?sort=resume_to_interview_rate&order=ASC → Lista vagas com menor taxa de conversão → Identifica problemas (requisitos restritivos, triagem inadequada) → Ajusta vagas → Refaz análise após 2 semanas

**Integração com Outros RFs:**
- **RF1 (Resumes):** total_resumes, resumes_last_7_days, resumes_uploaded (timeline), resume_to_interview_rate (funil)
- **RF2 (Jobs):** total_jobs, active_jobs, jobs_last_7_days, jobs_created (timeline), job_id/title/status (funil)
- **RF3 (Questions):** Usado indiretamente via entrevistas (perguntas geradas para interviews)
- **RF6 (Assessments):** Usado indiretamente via entrevistas (avaliações das respostas)
- **RF7 (Reports):** total_reports, reports_generated (timeline), recommendation='APPROVE' (funil)
- **RF8 (Interviews):** total_interviews, completed_interviews, interviews_last_7_days, interviews_scheduled (timeline), interview_to_approval_rate (funil)
- **RF10 (Users):** total_users, active_users, users_registered (timeline), user_id (presets ownership), shared_with_roles (sharing)

**Diferenças vs Outros RFs:**
- RF9: Agrega dados de todos os 7 RFs anteriores em visão consolidada (único RF "meta" que não cria novo domínio)
- Usa JSONB extensivamente para flexibilidade (filters, layout, preferences sem schema changes futuros)
- Único RF com sistema de "favorites/bookmarks" (presets são configurações salvas reutilizáveis)
- Função SQL que retorna JSON (get_dashboard_overview) vs. views simples de outros RFs
- Foco em analytics e visualização vs. CRUD de recursos de negócio
- 5 views de métricas vs. 2-3 views em outros RFs (maior complexidade de agregação)

---

### RF4 - Integração com GitHub API
**Status:** ✅ Concluído  
**Data:** 22/01/2025  
**Migrations:**
- ✅ 028_github_integration.sql - Tabela candidate_github_profiles (26 colunas) + 7 índices + 1 trigger + 1 view
- ✅ 029_github_metrics_views.sql - 5 views + função get_github_metrics() + 3 índices adicionais

**API Endpoints:**
- ✅ POST /api/candidates/:id/github (vincular GitHub username + sync automático)
- ✅ GET /api/candidates/:id/github (buscar perfil GitHub do candidato)
- ✅ PUT /api/candidates/:id/github (re-sincronizar dados do GitHub)
- ✅ DELETE /api/candidates/:id/github (remover integração - soft delete)
- ✅ GET /api/candidates/github (listar todos perfis GitHub com 5 filtros: search, sync_status, sort, page, limit)
- ✅ GET /api/dashboard/github/metrics (métricas consolidadas: 12 stats + top_languages + top_candidates + success_rate)
- ✅ GET /api/dashboard/github/sync-timeline (timeline diária de syncs com 5 métricas por data)
- ✅ GET /api/dashboard/github/top-languages (top N linguagens mais usadas)
- ✅ GET /api/dashboard/github/top-candidates (top N candidatos por popularidade)
- ✅ GET /api/dashboard/github/skills-distribution (distribuição de skills detectadas)

**Documentação:** ✅ RF4_DOCUMENTACAO.md (completa com integração GitHub API, rate limiting, LGPD, troubleshooting)  
**Testes:** ✅ RF4_GITHUB_API_COLLECTION.http (66 requests cobrindo CRUD, dashboard, E2E, segurança, performance, edge cases)

**Validação:**
- ✅ Migration 028 aplicada: candidate_github_profiles com 26 colunas, 2 FKs (candidate_id, company_id), 8 índices, 1 trigger (update_github_profiles_timestamps), 1 view (candidate_github_profiles_overview), 2 constraints
- ✅ Migration 029 aplicada: 5 views funcionais (integration_stats, sync_timeline, top_languages, top_candidates, skills_distribution), get_github_metrics() retorna JSON com 4 seções, 3 índices adicionais
- ✅ GitHubService implementado: Rate limiting, análise de repositórios, skills detection, completeness scoring
- ⏳ Testes reais contra servidor pendentes

**Estrutura de Dados:**
- **candidate_github_profiles:** Perfis GitHub vinculados a candidatos (26 colunas):
  * **Identity**: id, candidate_id, company_id, username, github_id
  * **Profile**: avatar_url, profile_url, bio, location, blog, company, email, hireable
  * **Stats**: public_repos, public_gists, followers, following
  * **Analysis (JSONB)**: summary com top_languages (top 10 com %), total_stars/forks, top_repos (top 5), recent_activity_count, last_activity_date, skills_detected (max 20), profile_completeness_score (0-100), original_repos_count, fork_repos_count
  * **Sync**: last_synced_at, sync_status (pending/syncing/success/error/rate_limited), sync_error
  * **Consent (LGPD)**: consent_given (obrigatório), consent_given_at
  * **Audit**: created_at, updated_at, deleted_at
- **GitHubService (servicos/githubService.js):** Cliente completo da GitHub API v3:
  * **Rate Limit Management**: Rastreia remaining + reset, isRateLimited() previne requests quando limitado, suporta GITHUB_TOKEN env var (5000 req/h vs 60 req/h)
  * **Methods**: getUserProfile(username), getUserRepositories(username, options), analyzeRepositories(repos), getCompleteProfile(username), getRateLimitInfo()
  * **Analysis Layer**: Extrai top_languages com %, total_stars/forks, top_repos, recent_activity, skills (de languages + topics filtrados), completeness_score (0-100), distingue original vs fork repos
  * **Error Handling**: 404 (user not found), 403 (rate limited), timeout, generic errors
- **Soft Delete:** deleted_at preserva auditoria, permite "direito ao esquecimento" (LGPD)
- **Multitenant:** Isolamento por company_id em todas as queries

**Features:**
- Integração opcional com consentimento explícito do candidato (LGPD compliance)
- Sync automático ao vincular username (busca profile + repos + análise)
- Re-sync manual para atualizar dados (útil para monitorar evolução do candidato)
- Análise avançada de repositórios:
  * Top 10 linguagens com percentuais de uso
  * Skills detectadas de languages + repo topics (filtrados, max 20)
  * Completeness score (0-100) baseado em atividade, repos, stars
  * Top 5 repos por stars com descrição
  * Contagem de repos originais vs forks (foca em trabalho original)
- Dashboard com 5 endpoints de métricas:
  * Métricas consolidadas (12 KPIs: total, syncs, averages, activity, stale profiles)
  * Timeline diária de syncs (success rate, volume temporal)
  * Top languages mais usadas na company (identifica stack técnico)
  * Top candidates por popularidade (ranking por stars + followers + repos)
  * Skills distribution (quais skills são mais comuns)
- Rate limit management:
  * Service rastreia limites client-side
  * Marca sync_status='rate_limited' quando bloqueado
  * Suporta GITHUB_TOKEN para 5000 req/h
- Filtros avançados: search (username/bio/location), sync_status, sort por followers/repos/last_sync
- Paginação: 20 itens default, max 100
- LGPD compliance: Consentimento obrigatório, soft delete preserva auditoria, dados públicos apenas

**Casos de Uso:**
1. **Enriquecer perfil técnico:** Recrutador vincula GitHub do candidato → Sistema busca repos/languages/stats → Gera análise automática → Exibe skills, popularidade, completeness score
2. **Avaliar experiência real:** Recrutador vê top_languages do candidato → Compara com requisitos da vaga → Verifica repos originais (não só forks) → Analisa atividade recente (last 6 months)
3. **Ranking técnico:** Gestor acessa top_candidates dashboard → Vê ranking por popularidade (stars + followers + repos) → Identifica desenvolvedores mais ativos/reconhecidos → Prioriza entrevistas
4. **Stack analysis:** Gestor visualiza top_languages da company → Identifica gap de skills (falta Python?) → Direciona recrutamento → Compara com mercado
5. **Monitorar evolução:** Candidato em processo → Recrutador re-sync após 2 semanas → Verifica novos commits/repos → Valida interesse genuíno por vaga

**Integração com Outros RFs:**
- **RF1 (Resumes):** candidates.id ← candidate_github_profiles.candidate_id; resume pode mencionar GitHub, integração valida/enriquece
- **RF2 (Jobs):** Comparar skills_detected do candidato com job_requirements; filtrar candidatos por linguagens da vaga
- **RF8 (Interviews):** Durante entrevista, mostrar GitHub profile do candidato; perguntas técnicas baseadas em repos/languages
- **RF9 (Dashboard):** Dashboard global pode incluir "% candidatos com GitHub", "Top skills na company"

**Diferenças vs Outros RFs:**
- RF4: Único RF com integração externa (GitHub API v3) vs. CRUD interno
- Usa JSONB extensivamente para análise flexível (summary field) sem schema changes futuros
- Rate limiting é concern único (GitHub API tem limites, precisa gerenciar)
- Opt-in feature (consentimento obrigatório) vs. core features (RFs 1-3, 6-10)
- Análise algorítmica (completeness score, popularity ranking) vs. apenas CRUD
- Client externo (githubService.js com axios) vs. apenas db queries
- Privacy critical (LGPD consent tracking) mais explícito que outros RFs

**Design Decisions:**
1. **JSONB summary:** Análise flexível (languages, skills, repos, scores) sem migrations futuras
2. **Consent tracking:** consent_given + consent_given_at explícitos para LGPD compliance
3. **Sync status enum:** 5-state machine (pending → syncing → success/error/rate_limited) para robustez
4. **Rate limit management:** Service rastreia GitHub API limits client-side para graceful degradation
5. **Analysis layer:** Não só armazenar raw data, extrair insights (language %, skill detection, completeness score)
6. **Fork filtering:** Focar em repos originais para skill assessment (forks menos indicativos)
7. **Skills detection:** Combinar languages + repo topics curados (max 20 skills)
8. **Completeness scoring:** Gamificação (0-100 score) incentiva candidatos a manter GitHub ativos
9. **Soft delete:** deleted_at preserva auditoria para LGPD "direito ao esquecimento"
10. **Multitenant isolation:** Todas queries filtram por company_id como outros RFs

---
