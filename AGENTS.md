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

1. Comece definindo que a arquitetura será multi-tenant com banco único e isolamento lógico por `company_id`. No seu domínio, “company” pode representar tanto Pessoa Jurídica (CNPJ) quanto Pessoa Física (CPF). O `company_id` será um UUID técnico, imutável e usado como chave estrangeira em todas as tabelas de negócio, garantindo que qualquer consulta possa ser filtrada por esse identificador.

2. Crie a tabela `companies` com os campos: `id` (UUID, PK), `type` (`'CPF'` ou `'CNPJ'`), `document` (VARCHAR, único, armazenado sem máscara), `name` (razão social ou nome completo) e `created_at`. Usar VARCHAR para `document` simplifica a entrada de CPF/CNPJ, permite validações no backend e evita problemas de formatação. Deixe a apresentação formatada (com pontos e traços) para a camada de front.

3. Crie a tabela `users` vinculada à `companies` por `company_id` (FK). Inclua `full_name`, `email` (único), `password_hash`, `role` (`USER`, `ADMIN`, `SUPER_ADMIN`), `is_active` e `created_at`. Isso permite ter um ou vários usuários associados ao mesmo `company_id`. Garanta índices em `email` e, quando fizer listagens administrativas, em `(company_id, created_at)`.

4. Em todas as tabelas de negócio (ex.: `jobs`, `resumes`, `interviews`, `applications`, `webhooks_logs`), adicione o campo `company_id` como FK para `companies(id)`. Crie índices compostos começando por `company_id` (por exemplo, `(company_id, created_at)`), pois a maioria das consultas filtrará por empresa; isso melhora muito a performance e a previsibilidade do plano de execução.

5. No backend, implemente validação de CPF/CNPJ no momento do cadastro de `companies`. Se `type='CPF'`, valide com o dígito verificador de CPF; se `type='CNPJ'`, valide como CNPJ. Normalize `document` removendo qualquer máscara antes de salvar e aplique a unicidade no banco (constraint UNIQUE), impedindo duplicidade de pessoa/empresa.

6. Estruture o fluxo de autenticação para retornar, no JWT, tanto o `sub` (id do usuário) quanto o `company_id` e o `role`. Ao efetuar login, o backend carrega o usuário pelo e-mail, valida a senha (Argon2id/bcrypt) e assina um access token curto e um refresh token rotativo. O payload deve incluir `company_id` para que o middleware possa isolar dados automaticamente.

7. Crie um middleware de autorização que leia o JWT, recupere `company_id` e `role`, injete isso no contexto da requisição e aplique o filtro em todas as queries. No ORM (Prisma/TypeORM/Sequelize), centralize funções repositório/serviço que sempre recebem `company_id` e o propagam para `where: { company_id }`. Esse ponto único evita “esquecimentos” de filtro em endpoints novos.

8. Opcionalmente, ative Row-Level Security (RLS) no PostgreSQL para uma segunda barreira no nível do banco. Ao abrir a conexão por requisição autenticada, execute `set_config('app.tenant_id', '<company_id>', true)` e crie políticas do tipo `USING (company_id = current_setting('app.tenant_id')::uuid)`. Assim, mesmo se alguém esquecer o filtro na aplicação, o banco impedirá vazamento entre empresas.

9. Modele os fluxos de cadastro. Primeiro, um endpoint para criar `companies` aceita `{ type: 'CPF'|'CNPJ', document: 'somente_dígitos', name }`. Depois, um endpoint para criar `users` recebe `{ company_id, full_name, email, password, role }`. Permita criar vários usuários para o mesmo `company_id`. Opcionalmente, ofereça convite por e-mail com token de primeiro acesso.

10. Implemente os fluxos de senha: “primeiro acesso” (token de criação com expiração curta que leva a uma tela para definir senha), “esqueci minha senha” (gera `reset_token` de uso único) e “trocar senha” (logado, exige `old_password`). Ao trocar senha, invalide sessões/refresh tokens anteriores (rotation + versioning) para mitigar sequestro de sessão.

11. Defina regras de permissão claras. `SUPER_ADMIN` enxerga dados de todos os `company_id` (para suporte e auditoria). `ADMIN` gerencia apenas usuários e recursos do próprio `company_id`. `USER` acessa e altera somente o que lhe for permitido dentro do tenant. Crie um guard `requireRole()` e aplique nos endpoints sensíveis, além de sempre validar a aderência do `company_id` da rota/registro ao `company_id` do token.

12. No front, ofereça ao criar a empresa um seletor de tipo (CPF/CNPJ), inputs com máscara apenas visual, mas envie ao backend apenas dígitos. Armazene a sessão preferencialmente em cookies `httpOnly` + `Secure` (especialmente no Flutter Web). Use guards de rota com base em `role` e exiba menus e dados sempre filtrados pelo `company_id` do usuário autenticado.

13. Complemente com camadas operacionais: crie uma tabela de auditoria (`audit_logs`) registrando `user_id`, `company_id`, `action`, `entity`, `entity_id`, `diff`, `ip`, `ua` e `created_at`. Adicione rate limiting em `/auth/login` e `/auth/forgot-password`. Programe backups automáticos e testes de restauração. Versione migrações com ferramenta (Prisma Migrate, Flyway, Liquibase).

14. Por fim, estabeleça um roteiro de testes: (a) criar `company` CPF e CNPJ; (b) criar múltiplos `users` no mesmo `company_id`; (c) logar como `USER` e garantir que só vê dados do próprio `company_id`; (d) logar como `ADMIN` e validar gestão de usuários apenas do seu tenant; (e) logar como `SUPER_ADMIN` e validar acesso global; (f) tentar intencionalmente acessar recursos de outro tenant e confirmar bloqueio pelo middleware e, se habilitado, pelo RLS.


Partindo da base multi-tenant já definida (banco único com isolamento lógico por `company_id` e fluxo de autenticação/autorização carregando `sub`, `company_id` e `role` no JWT), o DER do TalentMatchIA deve organizar-se em um núcleo de identidade e segurança e um domínio de recrutamento/entrevistas, sempre propagando `company_id` como FK e com índices compostos começando por `company_id`. No núcleo, além de `companies(id, type, document, name, created_at)`, `users(id, company_id, full_name, email, password_hash, role, is_active, created_at, updated_at, deleted_at)` e tabelas de suporte como `sessions/refresh_tokens` e `password_resets`, inclua `audit_logs(id, company_id, user_id, entity, entity_id, action, payload, created_at)` para trilha de auditoria e `webhooks_endpoints(id, company_id, url, secret, is_active, created_at)` + `webhooks_events(id, company_id, event_type, entity, entity_id, payload, created_at, delivered_at, status)` para integrações; arquivos devem ser tratados via `files(id, company_id, storage_key, filename, mime, size, created_at)` para centralizar metadados (currículos, relatórios, áudios). No domínio de recrutamento, modele `jobs(id, company_id, title, description, requirements, seniority, location_type, status, created_at, updated_at, slug)` como a entidade de vaga; `candidates(id, company_id, full_name, email, phone, linkedin, github_url, created_at, updated_at, unique(email, company_id))` como o cadastro do candidato; e um vínculo de candidatura `applications(id, company_id, job_id, candidate_id, source, stage, status, created_at, updated_at)` com histórico `application_status_history(id, company_id, application_id, from_status, to_status, note, created_at)` e anotações `notes(id, company_id, entity, entity_id, user_id, text, created_at)`. Para suportar o upload/parse de currículo e buscas no front, desdobre o currículo em `resumes(id, company_id, candidate_id, file_id, original_filename, parsed_text, parsed_json, created_at)` e, para facilitar filtros, normalize habilidades e experiências: `skills(id, company_id, name)`; `candidate_skills(candidate_id, skill_id, level)`; `job_skills(job_id, skill_id, must_have boolean)`; `experiences(id, company_id, candidate_id, company_name, role, start_date, end_date, description)`; `educations(id, company_id, candidate_id, institution, degree, start_date, end_date, description)`; crie índices GIN/trigrama em `resumes.parsed_text` e em colunas textuais de busca. A tela principal de entrevista do front pede uma estrutura explícita para sessões e QA: `interviews(id, company_id, application_id, scheduled_at, mode, status, created_at)`; `interview_sessions(id, company_id, interview_id, started_at, ended_at, transcript_file_id)`; `interview_questions(id, company_id, interview_id, origin enum['AI','MANUAL'], kind enum['TECNICA','COMPORTAMENTAL','SITUACIONAL'], prompt, created_at)`; `interview_answers(id, company_id, question_id, session_id, raw_text, audio_file_id, created_at)`; e a camada de avaliação da IA em `ai_feedback(id, company_id, answer_id, score numeric, verdict enum['FORTE','ADEQUADO','FRACO','INCONSISTENTE'], rationale_text, suggested_followups jsonb, created_at)`. Para refletir as telas de relatório e histórico, armazene `interview_reports(id, company_id, interview_id, summary_text, strengths jsonb, risks jsonb, recommendation enum['APROVAR','DÚVIDA','REPROVAR'], file_id, created_at)` e permita versionamento se o front re-gerar relatórios. A aba de GitHub/análise opcional no front mapeia `github_profiles(id, company_id, candidate_id, username, profile_url, fetched_at, stats jsonb)` e `github_repositories(id, company_id, profile_id, name, url, language, stars, forks, last_commit_at, metrics jsonb)`, servindo de insumo à geração de perguntas. Recursos transversais que aparecem em dashboards e filtros devem ter taxonomias reutilizáveis: `tags(id, company_id, name)` com tabelas de junção `job_tags(job_id, tag_id)` e `candidate_tags(candidate_id, tag_id)`; pipelines kanban por vaga em `pipelines(id, company_id, job_id, name)` e `pipeline_stages(id, company_id, pipeline_id, name, position)` vinculando em `application_stages(application_id, stage_id, entered_at)`. Para notificações/agenda exibidas no front (convites, lembretes), inclua `notifications(id, company_id, user_id, type, payload jsonb, read_at, created_at)` e `calendar_events(id, company_id, interview_id, ics_uid, starts_at, ends_at, created_at)`. Em todas as tabelas de negócio, padronize `id` UUID, `company_id` (FK → `companies`), `created_at/updated_at` e `deleted_at` para soft delete; imponha unicidades contextuais como `(company_id, slug)` em `jobs` e `(company_id, email)` em `candidates/users`; crie índices seletivos `(company_id, created_at)`, `(company_id, job_id)`, `(company_id, candidate_id)` e, para listagens administrativas, `(company_id, status)`; se optar por RLS no PostgreSQL, adote políticas `USING (company_id = current_setting('app.tenant_id')::uuid)` em todas as tabelas; por fim, complemente com `webhooks_logs`, `ingestion_jobs` e `transcriptions` se o front exibir progresso de processamento, garantindo que cada ação visível na UI tenha sua entidade de persistência correspondente no DER.