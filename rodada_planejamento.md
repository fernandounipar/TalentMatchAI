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
