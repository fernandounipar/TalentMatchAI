
## Como executar (dev)

- Backend (Node.js/Express + Prisma/PostgreSQL)
  - Configurar `.env` a partir de `backend/.env.example`
  - Criar banco no PostgreSQL e ajustar `DATABASE_URL`.
  - No diretório `backend/`:
    - `npm install`
    - `npx prisma generate`
    - `npx prisma migrate dev` (primeira vez)
    - `npm run dev` (API em `http://localhost:4000`)
  - Rotas principais: `/auth`, `/jobs`, `/resumes/upload`, `/interviews`, `/candidates`, `/history`, `/dashboard`.
  - Especificação OpenAPI: `openapi/talentmatchia.yaml`.

- Frontend (Flutter Web)
  - No diretório `frontend/`:
    - `flutter pub get`
    - Executar: `flutter run -d chrome` (ou `flutter build web`)
  - Variável de ambiente opcional para apontar a API: em `main.dart`, `API_BASE_URL` via `--dart-define`.

Observação: Recursos de IA usam OpenAI opcionalmente (`OPENAI_API_KEY`). Sem a chave, a API devolve respostas simuladas.

### 1. VisÃ£o Geral do Projeto

O TalentMatchIA Ã© uma ferramenta inovadora projetada para auxiliar recrutadores e profissionais de RH no processo de triagem de currÃ­culos e na conduÃ§Ã£o de entrevistas. Utilizando o poder da InteligÃªncia Artificial, o sistema visa otimizar a seleÃ§Ã£o de candidatos, fornecendo anÃ¡lises aprofundadas, sugerindo perguntas estratÃ©gicas e gerando relatÃ³rios objetivos, resultando em um processo de recrutamento mais eficiente, justo e baseado em dados.

### 2. Objetivo Principal

Desenvolver uma plataforma robusta e intuitiva que potencialize a capacidade dos recrutadores de identificar os melhores talentos, minimizando vieses e maximizando a eficÃ¡cia da seleÃ§Ã£o atravÃ©s de insights gerados por IA.

### 3. Escopo do Projeto (Funcionalidades Chave)

*   **Upload e AnÃ¡lise de CurrÃ­culos:**
    *   Permitir o upload de currÃ­culos em diversos formatos (PDF, DOCX).
    *   ExtraÃ§Ã£o inteligente de informaÃ§Ãµes chave (experiÃªncia, habilidades, educaÃ§Ã£o, etc.).
    *   AnÃ¡lise de compatibilidade do currÃ­culo com a descriÃ§Ã£o da vaga utilizando IA.
    *   GeraÃ§Ã£o de um score de compatibilidade.
*   **Assistente de Entrevista com IA:**
    *   SugestÃ£o de perguntas estratÃ©gicas e personalizadas para cada candidato, baseadas no currÃ­culo e na vaga.
    *   AuxÃ­lio em tempo real durante a entrevista (opcional, com consideraÃ§Ãµes de privacidade).
    *   AnÃ¡lise de respostas (se a entrevista for gravada ou transcrita e consentida).
*   **RelatÃ³rios e Dashboards:**
    *   GeraÃ§Ã£o de relatÃ³rios objetivos sobre o desempenho do candidato.
    *   Comparativos entre candidatos para uma mesma vaga.
    *   Dashboards com mÃ©tricas de recrutamento (tempo de contrataÃ§Ã£o, qualidade dos candidatos, etc.).
*   **Gerenciamento de Vagas:**
    *   Cadastro e ediÃ§Ã£o de descriÃ§Ãµes de vagas.
    *   AssociaÃ§Ã£o de candidatos a vagas especÃ­ficas.
*   **Gerenciamento de Candidatos:**
    *   VisualizaÃ§Ã£o e organizaÃ§Ã£o de perfis de candidatos.
    *   HistÃ³rico de interaÃ§Ãµes e feedback.
*   **Perfis de UsuÃ¡rios (Recrutadores):**
    *   AutenticaÃ§Ã£o segura.
    *   Gerenciamento de configuraÃ§Ãµes e preferÃªncias.

### 4. Arquitetura do Sistema

A arquitetura do TalentMatchIA serÃ¡ construÃ­da com uma abordagem de microsserviÃ§os e separaÃ§Ã£o de preocupaÃ§Ãµes, garantindo escalabilidade, flexibilidade e manutenibilidade.

*   **Front-end (Interface do UsuÃ¡rio):**
    *   **Tecnologia:** Flutter
    *   **PropÃ³sito:** Desenvolvimento de uma interface de usuÃ¡rio rica, responsiva e performÃ¡tica para aplicaÃ§Ãµes WEB e Mobile a partir de um Ãºnico codebase. FocarÃ¡ na experiÃªncia do usuÃ¡rio (UX) para recrutadores.
*   **Back-end (LÃ³gica de NegÃ³cios e APIs):**
    *   **Tecnologia:** Node.js
    *   **PropÃ³sito:** Servir como a camada central de processamento. IrÃ¡ gerenciar a lÃ³gica de negÃ³cios, autenticaÃ§Ã£o, autorizaÃ§Ã£o, comunicaÃ§Ã£o com o banco de dados e orquestraÃ§Ã£o dos serviÃ§os de InteligÃªncia Artificial.
    *   **Frameworks/Bibliotecas Potenciais:** Express.js, NestJS (para arquitetura mais estruturada), Mongoose (se houver uso de MongoDB em algum ponto, mas a prioridade Ã© PostgreSQL).
*   **Banco de Dados:**
    *   **Tecnologia:** PostgreSQL
    *   **PropÃ³sito:** Armazenamento robusto e relacional de todos os dados do sistema, incluindo perfis de recrutadores, dados de vagas, informaÃ§Ãµes de candidatos, resultados de anÃ¡lises de IA, histÃ³rico de entrevistas e relatÃ³rios. Escolhido por sua confiabilidade, integridade de dados e suporte a operaÃ§Ãµes complexas.
*   **MÃ³dulo/ServiÃ§os de InteligÃªncia Artificial (IA):**
    *   **Tecnologia:** Python (para desenvolvimento de modelos), APIs de IA de terceiros (ex: OpenAI, Google AI).
    *   **PropÃ³sito:** Componente responsÃ¡vel por todas as funcionalidades de IA, como anÃ¡lise de currÃ­culos (NLP), extraÃ§Ã£o de entidades, geraÃ§Ã£o de perguntas, e anÃ¡lise de dados para relatÃ³rios. Este mÃ³dulo serÃ¡ consumido pelo back-end Node.js via APIs.
    *   **ConsideraÃ§Ãµes:** PoderÃ¡ ser implementado como microsserviÃ§os dedicados (e.g., usando Flask ou FastAPI em Python) ou atravÃ©s de integraÃ§Ãµes diretas com plataformas de IA externas.

#### 4.1. Diagrama de Arquitetura Proposto
[ UsuÃ¡rio (Recrutador) ]
|
v
[ Aplicativo/PÃ¡gina WEB (Flutter) ]
| (RequisiÃ§Ãµes HTTP/API RESTful/GraphQL)
v
[ Servidor Back-end (Node.js) ]
| -- AutenticaÃ§Ã£o/AutorizaÃ§Ã£o
| -- LÃ³gica de NegÃ³cios
| -- ComunicaÃ§Ã£o com IA
| -- Armazenamento/RecuperaÃ§Ã£o de dados
v
[ MÃ³dulo/ServiÃ§o de IA ] <-- Pode ser:
| -- APIs de IA de Terceiros (OpenAI, etc.)
| -- Modelos de IA customizados (Python/Flask)
|
v
[ Banco de Dados (PostgreSQL) ]
-- Dados de Recrutadores
-- CurrÃ­culos (referÃªncias ou dados sanitizados)
-- HistÃ³rico de triagens/entrevistas
-- ConfiguraÃ§Ãµes de IA

![alt text](<Sem tÃ­tulo-1.png>)
