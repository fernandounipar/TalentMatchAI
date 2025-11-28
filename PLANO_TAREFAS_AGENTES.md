# Plano de Tarefas por Agente — TalentMatchIA (Foco Frontend)

Contexto rápido: frontend está ~95% conectado às APIs reais (ver `frontend/ALEX_FRONTEND_AUDITORIA_COMPLETA.md`), banco com 31 tabelas prontas (ver `backend/CHECKLIST_FINAL_DATABASE_MVP.md`), ainda há pontos legados e ajustes de UX/API. Objetivo deste plano é fechar gaps do MVP garantindo aderência aos requisitos RF1‑RF10 e RNFs, com atenção especial ao alinhamento Frontend ↔ Backend ↔ PostgreSQL.

## Mike – Líder de Equipe
- Consolidar escopo final de MVP (RF1‑RF10) e mapear dependências entre tarefas abaixo; destravar bloqueios entre frontend e backend.
- Rodar rota de verificação semanal: checar se `/api/curriculos/upload`, `/api/interviews/*` e `/api/usuarios` estão entregando payloads no formato `{data, meta}` esperado pelo Flutter.
- Garantir que todas as rotas críticas tenham responsáveis e prazos; registrar estado em `README_SETUP.md` e avisar quando pendências forem quitadas.
- Orquestrar validação cruzada: demo completa login → dashboard → vagas → candidatos → upload/IA → entrevista assistida → relatório → histórico → usuários/admin.

## Alex – Engenheiro (Frontend)
- Substituir dados mockados de relatórios por chamadas reais a `GET /api/interviews/:id/report` em `frontend/lib/telas/relatorios_tela.dart` e revisar `entrevista_assistida_tela.dart` para consumir `interview_reports` completos.
- Garantir que o fluxo de upload (`upload_curriculo_tela.dart`) usa o endpoint definitivo (`/api/curriculos/upload` ou alias definido pelo backend) e que o retorno mapeia `resumes`, `resume_analysis` e `files`.
- Criar tela/aba de Aplicações (pipeline) consumindo `/api/applications` + `/api/applications/:id/move` (kanban + histórico), alinhando estágios com `pipeline_stages`.
- Integrar visão GitHub em candidatos: consumir `GET /api/candidates/:id/github` e exibir linguagens/repos/seguidores quando houver `github_url`.
- Padronizar estados de loading/erro/vazio com banners acionáveis em `vagas_tela.dart`, `candidatos_tela.dart`, `entrevistas_tela.dart` e `relatorios_tela.dart`; adicionar botão “Tentar novamente”.
- Implementar guards de rota e storage seguro de tokens (web: `flutter_secure_storage` fallback via cookies/localStorage com expiração); impedir acesso a rotas internas quando `user.company` for nulo.

## Emma – Gerente de Produto
- Revisar aderência de cada RF (1‑10) frente às telas citadas na auditoria; definir critérios de aceite claros por fluxo (inputs, respostas, mensagens de erro, tempo máximo RNF1).
- Criar roteiro de UAT cobrindo jornada completa (login → upload → IA → entrevista → relatório → histórico → gestão de usuários) e registrar em `COMO_TESTAR.md`.
- Validar UX mínima para RH (RNF2/RNF7): responsividade, textos em PT-BR, mensagens claras; priorizar correções de copy antes da demo.
- Acompanhar remoção de legado para evitar regressões: confirmar que frontend não usa mais `/api/entrevistas` e que histórico/relatórios usam `interview_*`.

## David – Analista de Dados
- Conferir mapeamento Frontend ↔ tabelas: vagas (`jobs`), candidatos (`candidates` + `skills`), currículos (`resumes`/`resume_analysis`), entrevistas (`interviews`/`interview_messages`/`interview_reports`), aplicações (`applications` + `pipeline_stages`); sinalizar qualquer coluna ausente usada no Flutter.
- Validar função `get_dashboard_overview` e views de métricas com dados de teste multi-tenant; garantir que os números exibidos no dashboard batem com consultas SQL.
- Preparar dataset de demo seguro (seed) cobrindo upload analisado, entrevista com perguntas/respostas, relatório finalizado e usuários multi-role para que o frontend tenha dados reais.
- Revisar logs/auditoria (tabela `audit_logs`) para atender RNF9; confirmar que `GET /api/historico` retorna eventos coerentes com ações do frontend.

## Bob – Arquiteto de Software
- Entregar alias definitivo `/api/curriculos/upload` (ou alinhar com Alex para `/api/resumes/upload`) salvando em `resumes`, `files`, `resume_analysis`; retornar payload compatível com `upload_curriculo_tela.dart`.
- Concluir migração de legado: atualizar `interviews.js` e `historico.js` para usar `interview_messages`/`interview_reports`/`interviews`; remover rota antiga `/api/entrevistas` conforme `backend/ATENCAO_TABELAS_LEGACY_EM_USO.md`.
- Garantir CRUD completo exposto para `/api/applications`, `/api/usuarios` (list/put/delete) e `/api/interviews/:id/report`; documentar em `openapi`/`requests.http`.
- Aplicar hardening pendente (helmet, rate limiting, CORS) e revisar mensagens de erro semânticas para manter consistência com o tratamento do Flutter.
- Validar envelopes `{data, meta}` e campos esperados pelo frontend (ex.: `status`, `role`, `company`, `analise_json`, `overall_score`) antes da estabilização.

## Iris – Pesquisadora Profunda
- Avaliar melhores práticas de token storage e segurança para Flutter Web + Node (CSRF, XSS, refresh rotation) alinhadas a RNF3.
- Pesquisar integração GitHub (RF4) com limites de rate/quotas e caching; sugerir campos adicionais úteis para o frontend (linguagens dominantes, recência de commits).
- Mapear requisitos de conformidade/LGPD para uploads e logs de auditoria; sugerir textos de consentimento e políticas de retenção de dados.

---

Dependências cruzadas principais:
- Alex depende de Bob para endpoint de upload e normalização de `/api/interviews/*`.
- Emma/David precisam dos seeds e envelopes estáveis para UAT.
- Mike coordena a ordem: backend first (Bob), dados/seed (David), depois ajustes finais de UX (Alex) e UAT (Emma).
