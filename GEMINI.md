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