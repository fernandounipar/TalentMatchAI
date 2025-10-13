# 🎯 TalentMatchIA

Sistema inteligente de recrutamento e seleção com análise de currículos e entrevistas assistidas por IA.

![Flutter](https://img.shields.io/badge/Flutter-3.2.0-blue)
![Node.js](https://img.shields.io/badge/Node.js-18+-green)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 📋 Sobre o Projeto

O **TalentMatchIA** é uma ferramenta moderna de recrutamento que utiliza Inteligência Artificial para auxiliar recrutadores na triagem de currículos, condução de entrevistas e geração de relatórios objetivos.

### 🎯 Problemas que Resolve

- ✅ Grande volume de currículos para triagem manual
- ✅ Tempo significativo dedicado à análise de documentos
- ✅ Interpretação subjetiva das respostas em entrevistas
- ✅ Vieses e inconsistências no processo seletivo
- ✅ Falta de padronização nos relatórios

### 🚀 Principais Funcionalidades

#### MVP - Versão 1.0
- 📄 **Upload e Análise de Currículos**: Envio de PDFs/TXT com análise automática de competências
- 💼 **Gerenciamento de Vagas**: Cadastro e acompanhamento de vagas abertas
- 🤖 **Geração de Perguntas Inteligentes**: IA sugere perguntas personalizadas baseadas no currículo
- 🎤 **Entrevistas Assistidas**: Assistente IA em tempo real durante entrevistas
- 📊 **Relatórios Detalhados**: Análises completas com recomendações de contratação
- 📚 **Histórico de Processos**: Acompanhamento de todas as entrevistas realizadas
- 📈 **Dashboard Analítico**: Visão geral do funil de seleção

## 🛠️ Tecnologias Utilizadas

### Frontend
- **Flutter 3.2.0+** - Framework UI multiplataforma
- **Dart** - Linguagem de programação
- **HTTP** - Cliente REST
- **Provider** - Gerenciamento de estado

### Backend
- **Node.js 18+** - Runtime JavaScript
- **Express** - Framework web
- **PostgreSQL 14+** - Banco de dados relacional
- **OpenAI API** - Análise de IA (GPT-4)
- **Multer** - Upload de arquivos
- **pdf-parse** - Extração de texto de PDFs
- **JWT** - Autenticação
- **bcryptjs** - Criptografia de senhas

## Como executar (dev)

### Backend (Node.js/Express + PostgreSQL)
  
1. **Configure o `.env`** a partir de `backend/.env.example`
   ```env
   PORT=4000
   DATABASE_URL=postgresql://usuario:senha@localhost:5432/talentmatch
   JWT_SECRET=seu_secret_aqui
   OPENAI_API_KEY=sk-... # Opcional
   ```

2. **Crie banco no PostgreSQL** e ajuste `DATABASE_URL`

3. **No diretório `backend/`:**
   ```bash
   npm install
   npm run dev  # API em http://localhost:4000
   ```

**Nota:** O sistema usa **dados mockados** quando o banco de dados não está disponível, facilitando desenvolvimento e testes.

**Rotas principais:** 
- `/api/auth` - Autenticação
- `/api/vagas` - Gerenciamento de vagas
- `/api/curriculos/upload` - Upload de currículos
- `/api/entrevistas` - Entrevistas
- `/api/candidatos` - Candidatos
- `/api/historico` - Histórico
- `/api/dashboard` - Dashboard

**Especificação OpenAPI:** `openapi/talentmatchia.yaml`

### Frontend (Flutter Web)

No diretório `frontend/`:

```bash
flutter pub get
flutter run -d chrome  # Desenvolvimento web
# ou
flutter build web      # Build produção
```

**Variável de ambiente opcional:**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

## 🎮 Como Usar

### 1. Login na Plataforma
- Acesse a aplicação
- Faça login (qualquer email/senha em modo mockado)

### 2. Dashboard
- Visualize estatísticas gerais (vagas, candidatos, entrevistas)
- Acompanhe o funil de seleção
- Veja atividades recentes

### 3. Gerenciamento de Vagas
- Crie novas vagas com descrição e requisitos
- Filtre vagas por status (aberta, pausada, fechada)
- Edite ou exclua vagas

### 4. Upload de Currículo
- Selecione a vaga
- Faça upload do currículo (PDF/DOCX/TXT)
- Aguarde análise automática da IA

### 5. Análise de Currículo
- Visualize pontuação de compatibilidade
- Revise competências identificadas
- Veja perguntas sugeridas pela IA
- Inicie a entrevista

### 6. Entrevista Assistida
- Conduza entrevista com assistência da IA
- Receba sugestões de perguntas em tempo real
- A IA avalia respostas e fornece insights
- Grave observações

### 7. Relatório Final
- Visualize pontuação geral e recomendação
- Análise detalhada por competência
- Pontos fortes e de melhoria
- Exporte para PDF ou compartilhe

### 8. Histórico
- Acompanhe todas as entrevistas realizadas
- Filtre por candidato, vaga ou data
- Acesse relatórios anteriores

## 🔒 Segurança e Conformidade

### LGPD e GDPR
- ✅ Criptografia de dados sensíveis (AES-256)
- ✅ Consentimento explícito para coleta de dados
- ✅ Direito ao esquecimento
- ✅ Logs de auditoria
- ✅ Minimização de dados coletados

### Autenticação
- JWT (JSON Web Tokens)
- Bcrypt para hash de senhas
- Middleware de autenticação em rotas protegidas

## 📝 Requisitos

### Requisitos Funcionais (MVP)
- [x] **RF1**: Upload e análise de currículos (PDF/TXT)
- [x] **RF2**: Cadastro e gerenciamento de vagas
- [x] **RF3**: Geração de perguntas para entrevistas
- [ ] **RF4**: Integração opcional com GitHub API
- [ ] **RF5**: Transcrição de áudio da entrevista
- [ ] **RF6**: Avaliação em tempo real das respostas
- [x] **RF7**: Relatórios detalhados de entrevistas
- [x] **RF8**: Histórico de entrevistas
- [x] **RF9**: Dashboard de acompanhamento
- [ ] **RF10**: Gerenciamento de usuários (recrutadores/gestores)

### Requisitos Não Funcionais
- [x] **RNF1**: Resposta em até 10 segundos
- [x] **RNF2**: Interface simples e intuitiva
- [x] **RNF3**: Segurança com criptografia e LGPD/GDPR
- [x] **RNF5**: Escalabilidade
- [x] **RNF6**: Código modular e documentado
- [x] **RNF7**: Compatibilidade com navegadores
- [x] **RNF9**: Logs para auditoria

## 📄 Licença

Este projeto está sob a licença MIT.

## 👥 Autores

- **Equipe TalentMatchIA** - Desenvolvimento inicial
- GitHub: [@fernandounipar](https://github.com/fernandounipar)

---

**Desenvolvido com ❤️ usando Flutter e Node.js**

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
