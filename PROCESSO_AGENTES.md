# Processo Operacional dos Agentes TalentMatchIA

Este documento detalha como cada agente deve analisar, corrigir e evoluir o projeto TalentMatchIA (Flutter Web + Node.js + PostgreSQL + integrações de IA), garantindo alinhamento com os requisitos funcionais (RF1–RF10) e não funcionais (RNF1–RNF9) descritos em `AGENTS.md`.

## Visão Geral e Prioridades
- **Foco imediato (MVP)**: RF1, RF2, RF3, RF7, RF8, RF9, RF10 + RNF1, RNF2 e RNF6.
- **Objetivo de cada ciclo**: eliminar mocks, integrar front-back-db, assegurar autenticação e logs, e manter o tempo de resposta alinhado ao RNF1.
- **Entrega esperada por ciclo**: lista de gaps mapeados, tarefas atribuídas, critérios de aceitação claros e evidências de validação (logs, prints ou collections de API).

## Mike – Líder de Equipe
**Responsabilidades**
- Orquestrar planejamento e revisar entregas.
- Garantir que backlog e critérios de aceite reflitam os RF/RNF prioritários.

**Passos Operacionais**
1. **Mapeamento inicial**: revisar README, STATUS_IMPLEMENTACAO e estrutura de pastas para listar o que já cumpre cada RF/RNF.
2. **Backlog priorizado**: organizar tarefas por requisito (correção, melhoria, nova feature) começando pelo MVP.
3. **Distribuição**: atribuir tasks para Alex, Bob, David, Emma e Iris com escopos claros (ex.: “Alex: RF1 upload/IA + RNF1 tempo de resposta”).
4. **Critérios de aceite**: registrar, por RF/RNF, o que significa “pronto” (ex.: RF1: upload PDF/TXT + análise IA em <10s + log + testes básicos).
5. **Revisão por ciclo**: consolidar entregas, riscos e próximos passos em um resumo executivo.

## Alex – Engenheiro (Backend + Frontend)
**Responsabilidades**
- Implementar e integrar funcionalidades no Node.js e Flutter Web.

**Passos Operacionais**
1. **Backend**: inspecionar rotas/controladores/serviços e confirmar cobertura para RF1, RF2, RF3, RF7–RF10; mapear lacunas.
2. **Frontend**: revisar telas Flutter (upload, vagas, entrevistas, dashboard) e substituir dados mockados por chamadas reais.
3. **RF1 (Currículos)**: validar upload multipart (PDF/TXT), chamada de IA com timeout adequado e retornos de erro claros; garantir exibição de feedback e tempo dentro do RNF1.
4. **RF2/RF3 (Vagas & Perguntas)**: CRUD de vagas e geração de perguntas baseada em vaga+currículo+análise IA; conectar endpoints às telas.
5. **Segurança e Auth (RF10/RNF3)**: verificar JWT, escopo de rotas protegidas e tratamento de dados sensíveis; aplicar filtros por `company_id`.
6. **Remoção de mocks**: alinhar modelos front/back, padronizar DTOs e garantir estados de loading/erro no Flutter.

## Emma – Gerente de Produto
**Responsabilidades**
- Validar jornada do recrutador e definir o mínimo viável por RF/RNF.

**Passos Operacionais**
1. **Fluxo ponta a ponta**: confirmar que as telas cobrem cadastro de vaga → recepção/análise de currículo → roteiro de entrevista → registro → relatório → dashboard.
2. **Definição de MVP**: explicitar o escopo mínimo de cada RF prioritário (ex.: relatório simples em RF7 sem gráficos complexos).
3. **UX (RNF2)**: criar guia rápido de linguagem e navegação para RH (CTA claros, poucos cliques, estados de feedback).
4. **Critérios de aceite de negócio**: elaborar métricas de sucesso por etapa (ex.: “subir currículo, ver análise e perguntas em até 3 telas”).
5. **Planejamento pós-MVP**: listar o que pode ser postergado (RF4, RF5, RF6, RNF8 como meta evolutiva).

## David – Analista de Dados
**Responsabilidades**
- Garantir modelagem, métricas e auditoria alinhadas aos RF/RNF.

**Passos Operacionais**
1. **Banco e migrações**: revisar schema/migrations para tabelas de entrevistas, análises, usuários, histórico e logs.
2. **Métricas-chave**: definir KPIs (tempo médio de análise, currículos/vaga, conversão por etapa, uso de RFs) e sugerir queries.
3. **Auditoria (RNF9)**: propor/validar tabela de logs com usuário, operação, entidade, status e timestamp, filtrável por `company_id`.
4. **Dashboard (RF9)**: indicar dados mínimos para o MVP e as consultas correspondentes.
5. **Acurácia (RNF8)**: desenhar coleta de feedback de recrutadores e armazenamento para avaliar aderência da IA.

## Bob – Arquiteto de Software
**Responsabilidades**
- Garantir arquitetura escalável, segura e modular.

**Passos Operacionais**
1. **Mapeamento arquitetural**: documentar integrações front/back/DB/IA e checar multitenancy (`company_id`).
2. **Organização do backend**: recomendar camadas por domínio (auth, jobs, candidates, interviews, analytics) e reforçar RNF6.
3. **Serviço de IA central**: encapsular chamadas OpenAI/LLM com timeout, retry e logs.
4. **Segurança (RNF3)**: revisar tratamento de dados sensíveis, HTTPS, criptografia/mascaramento e adequação LGPD.
5. **Escalabilidade (RNF4/RNF5)**: propor uso de filas para cargas pesadas e sugerir limites para futura separação em serviços.
6. **Documentação técnica**: sugerir padrões (Swagger, `/docs`, diagramas simples) para novas features.

## Iris – Pesquisadora Profunda
**Responsabilidades**
- Trazer referências e melhores práticas para IA em recrutamento, UX e conformidade.

**Passos Operacionais**
1. **Benchmark de IA em RH**: reunir referências sobre análise de currículos, geração de perguntas e avaliação de respostas, incluindo mitigação de vieses.
2. **Prompts e estratégias (RF1/RF3/RF6)**: sugerir templates prontos para extração estruturada, perguntas alinhadas à vaga e avaliação de respostas.
3. **LGPD/GDPR (RNF3)**: listar obrigações práticas (consentimento, retenção, direitos do titular) e pontos de implementação no sistema.
4. **UX para RH (RNF2)**: recomendar padrões de UI para ATS (CTAs claros, redução de cliques, feedback imediato).
5. **Arquitetura SaaS**: compilar referências de multitenant segura em Node.js + PostgreSQL (RLS, `company_id`, segregação lógica) para Bob.

## Governança de Ciclo
1. **Kickoff de ciclo**: Mike coleta status, ajusta backlog e publica tarefas atribuídas.
2. **Execução**: cada agente registra entregas e bloqueios diários.
3. **Revisão**: validação cruzada (Mike + responsável técnico) com base nos critérios de aceite.
4. **Consolidação**: resumo executivo com evidências (prints, logs, consultas) e próximos passos.

---
**Observação**: seguir as diretrizes de `AGENTS.md` (sem mocks em código, uso de dados do banco e alinhamento ao layout Figma) e priorizar sempre RF/RNF marcados como MVP.
