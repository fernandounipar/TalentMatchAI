# Rodada – Kickoff de Triagem de Currículos (RF1)

## 1. Mike – Líder de Equipe (início da rodada)
- Problema foco: **RF1 – Upload e análise de currículos (PDF/TXT)** atendendo RNF1 (tempo < 10s), RNF3 (LGPD) e RNF6 (código modular).
- Objetivo da rodada: entregar fluxo ponta a ponta sem mocks, integrado a banco/IA, alinhado ao layout Figma.
- Tasks abertas:
  - **Iris:** compilar referências de IA aplicada a triagem e LGPD.
  - **Emma:** definir MVP, jornadas e critérios de aceite de RF1.
  - **Bob:** desenhar arquitetura (rota, segurança, integração IA/DB) e contratos.
  - **Alex:** implementar backend Node.js + frontend Flutter Web conforme arquitetura.
  - **David:** mapear métricas/KPIs e tabelas/logs para monitorar RF1.

## 2. Iris – Pesquisadora Profunda
- Melhores práticas de IA em triagem:
  - Extrair dados estruturados do currículo com schema JSON (contato, experiências, skills, senioridade) e validação de formato.
  - Usar **prompts de extração + chain-of-thought oculto** para melhorar precisão e justificar recomendações.
  - Limitar contexto: dividir PDF em seções e aplicar embeddings somente se exceder limite de tokens.
- LGPD e vieses:
  - Minimizar coleta: mascarar dados sensíveis (CPF, endereço completo) e evitar atributos protegidos na decisão.
  - Consentimento registrado via checkbox/log antes do upload; permitir exclusão sob requisição.
  - Registrar fonte e finalidade de uso do dado; manter retenção curta para currículos não vinculados.
- Segurança operacional:
  - Sanitizar PDFs (filtros de MIME/extensão, antivírus opcional), limite de tamanho (ex.: 5MB) e timeouts de IA.
  - Logs estruturados sem campos sensíveis; armazenar feedback do recrutador para RNF8.

## 3. Emma – Gerente de Produto
- MVP e fluxo de usuário:
  1. Recrutador acessa página Currículos, faz upload de PDF/TXT.
  2. Sistema confirma recebimento, mostra estado de processamento e tempo estimado.
  3. Após processamento, exibe resumo do candidato (contato, cargo desejado, principais experiências/skills) e **perguntas sugeridas** para entrevista.
  4. Usuário pode baixar/visualizar análise e enviar feedback (útil/não útil + comentário curto).
- Critérios de aceitação:
  - Upload aceita PDF/TXT até 5MB; falhas retornam mensagem clara.
  - Tempo médio de resposta < 10s em ambiente padrão.
  - Resultado inclui ao menos: nome, e-mail mascarado, senioridade inferida, top skills (5), 3–5 perguntas customizadas.
  - Dados persistem vinculados a `company_id` e usuário autenticado; nenhuma informação sensível exposta além do necessário.
  - Estados de loading/erro vazios e tratativas de retry.

## 4. Bob – Arquiteto de Software
- Backend Node.js:
  - Rota `POST /api/resumes/analyze` protegida por auth middleware (extrai `user_id` e `company_id`).
  - Fluxo: validação → upload para storage local/S3 → OCR/parsing → serviço de IA → gravação em PostgreSQL (`resumes`, `resume_analysis`, `analysis_feedback`).
  - Serviço de IA encapsulado (`services/ai/resumeAnalysisService.ts`) com timeout, retry e logs; prompt recebe vaga opcional.
  - Resposta limpa de PII (mascara e-mail/telefone) antes de retornar.
- Frontend Flutter Web:
  - Tela `curriculos_tela.dart` chama endpoint via provider/bloc; estados de loading, sucesso, erro.
  - Componentes alinhados ao design system (`tm_colors`, `tm_text`); sem dados mockados.
- Banco de dados:
  - Tabelas/colunas: `resumes(id, candidate_name, email, phone, company_id, user_id, source, created_at)`, `resume_analysis(id, resume_id, summary jsonb, questions jsonb, score numeric, created_at)`, `analysis_feedback(id, resume_id, user_id, company_id, useful boolean, comment text, created_at)`.
  - Índices em `company_id`, `created_at`; constraints de FK e checks de tamanho/formatos.
- Segurança/escalabilidade:
  - Filtrar todas as consultas por `company_id`; armazenar arquivos em bucket segregado por tenant.
  - Rate limiting por IP/usuário na rota de análise; logs com request_id sem dados sensíveis.

## 5. Alex – Engenheiro (implementação)
- Backend:
  - Implementar controller `resumeController` com validação de MIME e tamanho, uso de multer/storage e chamada ao serviço de IA.
  - Persistir registros via repositórios PostgreSQL; aplicar transação para upload + análise.
  - Normalizar DTO de resposta para frontend (`summary`, `skills`, `questions`, `processingTimeMs`).
- Frontend:
  - Criar form de upload no Flutter com progresso; integrar provider/bloc para disparar requisição e renderizar resultado.
  - Exibir cartões de resumo/skills/perguntas usando componentes existentes; mensagens de erro/timeout.
  - Enviar feedback opcional pós-análise para `POST /api/resumes/{id}/feedback`.
- Integração IA:
  - Usar serviço central com prompt de extração; logs de tokens/duração em nível debug apenas.

## 6. David – Analista de Dados
- Métricas/KPIs para RF1:
  - Tempo médio de processamento (upload → resposta) por `company_id` e por origem.
  - Taxa de sucesso/erro por tipo de arquivo e tamanho.
  - Aderência percebida: % de feedback “útil”.
  - Volume de currículos analisados por vaga e por semana.
- Implementação de dados:
  - Views ou queries para dashboard (`resume_processing_stats`, `resume_feedback_stats`).
  - Logs/auditoria: registrar usuário, operação (upload/analyze/feedback), status e timestamp.

## 7. Mike – Líder de Equipe (fechamento da rodada)
- Validação: critérios de aceitação cumpridos, arquitetura respeita filtros por `company_id`, e dados persistem sem mocks.
- Evidências esperadas: collection de chamadas `POST /api/resumes/analyze`, prints da tela de Currículos com loading/sucesso/erro e consultas no PostgreSQL mostrando registros.
- Próximos passos: expandir para RF2 (vagas) e integrar perguntas geradas ao fluxo de entrevistas (RF3/RF7), mantendo mesmas práticas de segurança e medição.

---

# Rodada – Kickoff de Triagem de Currículos (RF1)

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

---

# Rodada – Cadastro e Gerenciamento de Vagas (RF2)

## 1. Mike – Líder de Equipe (kickoff)
- Meta: entregar CRUD completo de vagas (RF2) com filtros por `company_id`, respeitando RNF2, RNF3, RNF5 e RNF6.
- Diretrizes: telas alinhadas ao Figma, integrações reais com DB e autenticação ativa.
- Ativações iniciais:
  - **Iris:** mapear práticas de privacidade e nomenclatura de cargos; revisar benchmarks de formulários de vagas.
  - **Emma:** definir fluxo (criar/editar/duplicar/publicar vaga) e critérios de aceitação.
  - **Bob:** fechar contratos de API e política de permissões (recrutador vs gestor).
  - **Alex:** preparar backlog técnico (migrations, rotas, UI) sem mocks.
  - **David:** definir métricas de pipeline (vagas abertas, tempo de publicação, funil por vaga).

## 2. Iris – Pesquisadora Profunda
- Recomendar taxonomia de cargos e skills para autocomplete, evitando termos discriminatórios.
- Garantir consentimento e aviso de privacidade no formulário; campos obrigatórios mínimos para RNF2.
- Sugestões de validação: limite de caracteres, máscara de salários, verificação de localização.

## 3. Emma – Gerente de Produto
- Jornada: criar vaga → salvar rascunho → publicar → pausar/fechar → histórico de alterações.
- Critérios de aceitação: formulário responsivo, mensagens claras, edição segura (controle de concorrência otimista), filtros por status.
- Interfaces: cards/lista de vagas com status, contadores e busca textual.

## 4. Bob – Arquiteto de Software
- Backend: rotas `POST/PUT/GET /api/jobs` com auth e filtros por `company_id`; versionar descrições de vaga.
- Banco: tabelas `jobs`, `job_revisions`, índices em `status`, `company_id`, `updated_at`; triggers para histórico.
- Frontend: `vagas_tela.dart` usando bloc/provider, estados de loading/erro, paginação e busca.
- Segurança/escala: rate limiting em criação/edição, validação de payload, logs de alteração para RNF9.

## 5. Alex – Engenheiro
- Implementar migrations e repositórios PostgreSQL; DTOs consistentes com `job_revisions`.
- Construir formulários Flutter com validação local e mensagens inline; integração com endpoints reais.
- Entregar componentes reutilizáveis (autocomplete de skills, editor de descrição com markdown leve).

## 6. David – Analista de Dados
- KPIs: tempo até publicação, vagas ativas vs fechadas, volume de candidatos por vaga.
- Assets de dados: view `job_stats_overview`, logs de alterações por usuário; preparar export CSV (RNF7).

## 7. Mike – Fechamento
- Evidências: collection de chamadas CRUD, prints da tela de vagas com filtros, queries validando filtros por `company_id`.
- Próximo passo: conectar vagas a geração de perguntas (RF3) e triagem (RF1).

---

# Rodada – Geração de Perguntas para Entrevistas (RF3)

## 1. Mike – Líder de Equipe (kickoff)
- Objetivo: entregar serviço de geração de perguntas customizadas por vaga/candidato, alinhado a RNF1, RNF2, RNF3 e RNF8.
- Alinhamentos: IA deve considerar descrição da vaga (RF2) e análise de currículo (RF1).
- Delegações:
  - **Iris:** melhores prompts e mitigação de vieses em perguntas.
  - **Emma:** jornada de geração/curadoria e critérios de qualidade.
  - **Bob:** contratos de API e caching.
  - **Alex:** implementação front/back.
  - **David:** métricas de aderência das perguntas e feedback dos recrutadores.

## 2. Iris – Pesquisadora Profunda
- Criar prompt de geração com guarda contra perguntas ilegais/discriminatórias e com chain-of-thought oculto.
- Catálogo de tipos de pergunta (comportamental, técnica, situacional) e níveis de senioridade.
- Roteiro de validação humana: checklist de viés, clareza e adequação ao idioma.

## 3. Emma – Gerente de Produto
- Fluxo: selecionar vaga e candidato → gerar perguntas → permitir editar/reordenar → salvar pacote de entrevista.
- Critérios: 5–10 perguntas contextualizadas; opção de marcar favoritas; histórico por vaga; UI responsiva.
- Estados: loading/erro, limite de geração por minuto (mensagem amigável).

## 4. Bob – Arquiteto de Software
- Backend: `POST /api/interviews/questions` recebendo `job_id` + `resume_id`; caching por combinação vaga/candidato.
- Serviço IA dedicado com timeout e fallback; sanitizar PII antes do envio ao modelo.
- Banco: tabelas `interview_question_sets` e `interview_questions` com FK para vaga/candidato.
- Frontend: componentes em `entrevistas_tela.dart` para listar e editar perguntas; salvar revisões.

## 5. Alex – Engenheiro
- Implementar rota com validação e cache; persistir conjuntos e histórico de revisões.
- UI: modal ou painel para geração e edição; suporte a drag & drop simples para reordenar.
- Telemetria: logar tempo de geração, tokens e feedback de utilidade.

## 6. David – Analista de Dados
- KPIs: tempo médio de geração, % de perguntas aceitas/alteradas, satisfação (feedback).
- Views: `interview_question_stats` com agregação por vaga, recrutador e senioridade.

## 7. Mike – Fechamento
- Evidências: conjunto salvo e reutilizado em entrevista, logs sem PII, testes de carga leves no endpoint.
- Próximo passo: conectar perguntas à avaliação em tempo real (RF6) e relatórios (RF7).

---

# Rodada – Integração opcional com GitHub API (RF4)

## 1. Mike – Líder de Equipe (kickoff)
- Meta: complementar perfil técnico com dados do GitHub, respeitando LGPD (RNF3) e performance (RNF1/RNF5).
- Checkpoints: consentimento explícito do candidato; desligável por empresa.

## 2. Iris – Pesquisadora Profunda
- Boas práticas de privacidade: solicitar username explicitamente; evitar scrape; respeitar termos da API.
- Propor heurísticas de avaliação (commits, stacks, principais repositórios) sem ranking discriminatório.

## 3. Emma – Gerente de Produto
- Fluxo: recrutor adiciona username GitHub → sistema coleta dados → exibe resumo (repos destaque, linguagem, atividade recente).
- Critérios: deixar claro que é opcional; tempo de resposta < 5s com uso de cache local.

## 4. Bob – Arquiteto de Software
- Backend: serviço `githubProfileService` com caching e rate limiting; rota `POST /api/candidates/github-sync`.
- Banco: tabelas `candidate_repos`, `candidate_languages`; job assíncrono para sincronização.
- Frontend: painel de GitHub no perfil do candidato, com status de sincronização e botão de refresh.
- Segurança: armazenar somente dados públicos; limpeza automática após período configurável.

## 5. Alex – Engenheiro
- Implementar client GitHub com ETags/cache; retries com backoff; testes de contrato.
- UI: cards de atividade, linguagens e repos; mensagens claras para limites de API.

## 6. David – Analista de Dados
- KPIs: % de candidatos com GitHub, tempo de sincronização, erros de rate limit.
- Views: `github_sync_stats` e logs de erro para auditoria (RNF9).

## 7. Mike – Fechamento
- Evidências: sincronização bem-sucedida em ambiente de teste, logs sem dados sensíveis e opção de desligar por empresa.

---

# Rodada – Transcrição de Áudio da Entrevista (RF5)

## 1. Mike – Líder de Equipe (kickoff)
- Objetivo: permitir upload/gravação e transcrição com tempo adequado (RNF1) e segurança (RNF3).
- Coordenação: garantir compatibilidade cross-browser (RNF7) e escala para múltiplas salas (RNF5).

## 2. Iris – Pesquisadora Profunda
- Avaliar modelos de ASR e limites de tempo; recomendar formatos/bitrates suportados.
- Checklist de privacidade: avisos de gravação, consentimento, retenção curta de áudio.

## 3. Emma – Gerente de Produto
- Fluxo: iniciar entrevista → gravar ou subir áudio → acompanhar progresso → visualizar transcrição com timestamps.
- Critérios: suporte a uploads de até X minutos/MB, mensagens de erro claras, download da transcrição.

## 4. Bob – Arquiteto de Software
- Backend: rota `POST /api/interviews/transcript` com storage seguro; job assíncrono para transcrição.
- Infra: filas para processamento; callbacks/webhooks para atualizar status.
- Banco: `interview_recordings`, `interview_transcripts` com índices por `company_id` e `interview_id`.
- Frontend: componente de upload/progresso e visualização de transcript em `entrevistas_tela.dart`.

## 5. Alex – Engenheiro
- Implementar gravação web (quando suportado) e upload com barra de progresso; polling para status do job.
- Integrar serviço de ASR com timeout e retries; limpar arquivos temporários.

## 6. David – Analista de Dados
- KPIs: tempo de transcrição, taxa de erro por formato, satisfação do usuário.
- Views: `transcription_stats`; logs para auditoria de acesso ao áudio (RNF9).

## 7. Mike – Fechamento
- Evidências: upload e transcrição concluídos em ambiente de teste, histórico por entrevista e logs de acesso.

---

# Rodada – Avaliação em Tempo Real das Respostas (RF6)

## 1. Mike – Líder de Equipe (kickoff)
- Meta: scoring em tempo real durante entrevista com latência baixa (RNF1) e UI responsiva (RNF2/RNF7).
- Pauta: fairness e transparência (RNF3/RNF8); fallback quando IA indisponível.

## 2. Iris – Pesquisadora Profunda
- Definir critérios objetivos de avaliação por competência; prompts de scoring com explicabilidade.
- Limitar coleta de dados sensíveis; evitar feedback enviesado.

## 3. Emma – Gerente de Produto
- Fluxo: entrevistador seleciona pergunta → sistema captura resposta (texto/áudio) → exibe score e rationale.
- Critérios: latência < 3s para scoring textual; indicar quando avaliação é automática ou manual.

## 4. Bob – Arquiteto de Software
- Backend: serviço de streaming ou websockets para envio/recebimento de avaliações.
- Banco: `live_assessments` com snapshots por pergunta; flags de “manual override”.
- Frontend: componente em tempo real no painel de entrevista com estados de loading/erro.
- Segurança: limitar payloads, logs sem conteúdo sensível; throttling por sessão.

## 5. Alex – Engenheiro
- Implementar canal websocket/event-source; UI com atualização incremental.
- Fallback para avaliação batch se tempo exceder limite; testes de carga leve.

## 6. David – Analista de Dados
- KPIs: latência média, % de avaliações automáticas vs manuais, concordância com avaliador humano.
- Views: `live_assessment_metrics` com agregação por vaga e entrevistador.

## 7. Mike – Fechamento
- Evidências: sessão demo com avaliação em tempo real, métricas de latência registradas, rotas protegidas.

---

# Rodada – Relatórios Detalhados de Entrevistas (RF7)

## 1. Mike – Líder de Equipe (kickoff)
- Objetivo: consolidar resultados de entrevistas em relatórios exportáveis, cumprindo RNF2, RNF3, RNF7 e RNF9.
- Alinhamento: integrar dados de RF3, RF5 e RF6.

## 2. Iris – Pesquisadora Profunda
- Recomendar estrutura de relatório: resumo, pontos fortes, riscos, recomendação e trilha de auditoria.
- Garantir anonimização quando exportado; alertas sobre vieses.

## 3. Emma – Gerente de Produto
- Fluxo: selecionar entrevista → gerar relatório → permitir notas manuais → exportar PDF/CSV.
- Critérios: filtros por vaga e período; indicadores visuais; estados de geração.

## 4. Bob – Arquiteto de Software
- Backend: rota `GET /api/interviews/{id}/report` com composição de dados e cache.
- Banco: views materializadas para KPIs; tabela `interview_reports` para armazenar versões.
- Frontend: `relatorios_tela.dart` com cards e export; loading/erro claros.
- Segurança: remover PII em export; registrar quem gerou/baixou (RNF9).

## 5. Alex – Engenheiro
- Implementar gerador de PDF/CSV server-side; endpoints de download com auth.
- UI para notas manuais e indicadores; testes de export cross-browser.

## 6. David – Analista de Dados
- KPIs: taxa de aprovação, tempo por etapa, correlação entre perguntas e performance.
- Views: `interview_report_kpis`; logs de download/export.

## 7. Mike – Fechamento
- Evidências: relatório salvo e exportado; auditoria de downloads; performance aceitável.

---

# Rodada – Histórico de Entrevistas (RF8)

## 1. Mike – Líder de Equipe (kickoff)
- Meta: oferecer histórico completo e filtrável de entrevistas, mantendo RNF2, RNF3, RNF7 e RNF9.
- Escopo: listagem, filtros, detalhes, replays de transcrição/respostas.

## 2. Iris – Pesquisadora Profunda
- Regras de retenção e anonimização; destacar melhores práticas de pesquisa por datas/status.

## 3. Emma – Gerente de Produto
- Fluxo: filtros por vaga, candidato, status e período; acesso rápido a relatórios e transcrições.
- Critérios: paginação, buscas textuais, indicadores de status; UX consistente com dashboard.

## 4. Bob – Arquiteto de Software
- Backend: `GET /api/interviews` paginado; `GET /api/interviews/{id}` com detalhes e links para transcripts/relatórios.
- Banco: índices em `status`, `job_id`, `candidate_id`, `company_id`; view resumida para dashboard.
- Frontend: `historico_tela.dart` com filtros salvos e export leve.
- Segurança: autorizações por papel; logs de acesso (RNF9).

## 5. Alex – Engenheiro
- Implementar endpoints e repositórios com filtros seguros; paginação keyset quando possível.
- UI com filtros persistentes e estados de carregamento; deep links para detalhes.

## 6. David – Analista de Dados
- KPIs: volume de entrevistas por período, status de conclusão, tempo médio de resposta.
- Views: `interview_history_stats`; auditoria de acessos.

## 7. Mike – Fechamento
- Evidências: listagem paginada funcionando, filtros preservando contexto e auditoria ativa.

---

# Rodada – Dashboard de Acompanhamento (RF9)

## 1. Mike – Líder de Equipe (kickoff)
- Objetivo: dashboard unificado com KPIs de triagem, vagas e entrevistas, respeitando RNF1, RNF2 e RNF7.
- Integração: consumir views de RF1, RF2, RF3, RF5, RF6 e RF8.

## 2. Iris – Pesquisadora Profunda
- Selecionar métricas-chave focadas em ação (lag/lead indicators) e layouts que evitem viés de interpretação.

## 3. Emma – Gerente de Produto
- Fluxo: carregamento rápido (<3s), filtros globais por período/empresa/unidade; cards e gráficos responsivos.
- Critérios: estados de loading/erro, export rápido para CSV/PNG, tooltips claros.

## 4. Bob – Arquiteto de Software
- Backend: endpoints agregadores (`/api/dashboard/overview`, `/api/dashboard/kpis`) com cache e feature flags.
- Banco: materialized views atualizadas em batch; índices para suportar agregações.
- Frontend: `dashboard_tela.dart` com componentes reutilizáveis e skeletons.
- Segurança: limitar escopo por `company_id` e papel; logs de acesso.

## 5. Alex – Engenheiro
- Implementar chamadas com caching e revalidação; gráficos usando componentes existentes.
- Otimizar carregamento com paralelismo e tratamento de erros.

## 6. David – Analista de Dados
- KPIs: conversão por etapa, SLA de transcrição, produtividade de triagem, volume de vagas.
- Views: `dashboard_overview`, `dashboard_kpis`; monitorar frescor dos dados.

## 7. Mike – Fechamento
- Evidências: dashboard respondendo em <3s com dados reais; coleta de feedback de UX.

---

# Rodada – Gerenciamento de Usuários (RF10)

## 1. Mike – Líder de Equipe (kickoff)
- Meta: gestão segura de usuários/roles, cobrindo RNF2, RNF3, RNF5 e RNF9.
- Regras: mínimo privilégio, trilha de auditoria e UX simples para convites e resets.

## 2. Iris – Pesquisadora Profunda
- Boas práticas de identidade: MFA opcional, políticas de senha, proteção contra enumeração de usuários.
- Conformidade: consentimento e termos; retenção e exclusão de contas.

## 3. Emma – Gerente de Produto
- Fluxo: convite por e-mail → aceite → definição de senha → escolha de perfil (recrutador/gestor/admin).
- Critérios: edição de perfil, bloqueio/desbloqueio, reset seguro, logs visíveis para admins.

## 4. Bob – Arquiteto de Software
- Backend: rotas para gestão de usuários/roles (`/api/users`, `/api/roles`), tokens de convite e reset.
- Banco: tabelas `users`, `roles`, `user_roles`, `invitations`, `password_resets` com expiração.
- Frontend: `configuracoes_tela.dart` ou equivalente para administração de contas.
- Segurança: hashing forte, rate limiting de login/reset, RLS por `company_id`, auditoria completa.

## 5. Alex – Engenheiro
- Implementar fluxo de convite e onboarding; formulários com validação e feedback.
- Integração com provider de e-mail; testes de rotas protegidas e middlewares.

## 6. David – Analista de Dados
- KPIs: convites aceitos, tempo de ativação, sessões ativas, falhas de login.
- Views: `user_management_stats`; logs estruturados para RNF9.

## 7. Mike – Fechamento
- Evidências: criação/convite/reset funcionando, trilha de auditoria e validação de escopos por `company_id`.
