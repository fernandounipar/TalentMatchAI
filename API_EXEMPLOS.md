# 📡 Exemplos de Uso da API - TalentMatchIA

## 🔐 Autenticação

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "recrutador@empresa.com",
  "senha": "senha123"
}
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "usuario": {
    "id": "1",
    "nome": "Recrutadora",
    "email": "recrutador@empresa.com"
  }
}
```

### Usar Token em Requisições
```http
GET /api/vagas
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 💼 Vagas

### Listar Todas as Vagas
```http
GET /api/vagas
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
[
  {
    "id": "1",
    "titulo": "Desenvolvedor Full Stack",
    "descricao": "Desenvolver e manter aplicações web...",
    "requisitos": "React, Node.js, PostgreSQL, 3+ anos",
    "status": "aberta",
    "tecnologias": "React, Node.js, PostgreSQL, Docker",
    "nivel": "Pleno",
    "criado_em": "2024-09-15T08:00:00Z"
  }
]
```

### Criar Nova Vaga
```http
POST /api/vagas
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "titulo": "Product Manager",
  "descricao": "Liderar roadmap de produto e definir prioridades",
  "requisitos": "Gestão de produtos, Agile, 5+ anos",
  "status": "aberta",
  "tecnologias": "Jira, Miro, Analytics",
  "nivel": "Senior"
}
```

**Resposta:**
```json
{
  "id": "7",
  "titulo": "Product Manager",
  "descricao": "Liderar roadmap de produto e definir prioridades",
  "requisitos": "Gestão de produtos, Agile, 5+ anos",
  "status": "aberta",
  "tecnologias": "Jira, Miro, Analytics",
  "nivel": "Senior",
  "criado_em": "2025-10-12T10:30:00Z"
}
```

### Buscar Vaga por ID
```http
GET /api/vagas/1
Authorization: Bearer <TOKEN>
```

### Atualizar Vaga
```http
PUT /api/vagas/1
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "status": "pausada",
  "requisitos": "React, Node.js, PostgreSQL, Docker, 4+ anos"
}
```

### Deletar Vaga
```http
DELETE /api/vagas/1
Authorization: Bearer <TOKEN>
```

## 👥 Candidatos

### Listar Candidatos
```http
GET /api/candidatos
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
[
  {
    "id": "1",
    "nome": "João Silva",
    "email": "joao.silva@email.com",
    "telefone": "(11) 98765-4321",
    "linkedin_url": "https://linkedin.com/in/joaosilva",
    "github_url": "https://github.com/joaosilva",
    "qtd_curriculos": 2,
    "qtd_entrevistas": 3,
    "criado_em": "2024-10-01T10:00:00Z"
  }
]
```

## 📄 Currículos

### Upload de Currículo
```http
POST /api/curriculos/upload
Authorization: Bearer <TOKEN>
Content-Type: multipart/form-data

arquivo: [arquivo.pdf]
candidato: {
  "nome": "João Silva",
  "email": "joao@email.com",
  "github": "https://github.com/joaosilva"
}
vagaId: "1"
```

**Resposta:**
```json
{
  "id": "123",
  "candidato_id": "1",
  "vaga_id": "1",
  "nome_arquivo": "curriculo_joao_silva.pdf",
  "analise_ia": {
    "pontuacao": 85,
    "competencias": ["React", "Node.js", "PostgreSQL"],
    "experiencia_anos": 5,
    "pontos_fortes": ["Sólida experiência com stack"],
    "pontos_atencao": ["Testes automatizados"]
  },
  "criado_em": "2025-10-12T10:35:00Z"
}
```

### Buscar Análise de Currículo
```http
GET /api/curriculos/123/analise
Authorization: Bearer <TOKEN>
```

## 🎤 Entrevistas

### Buscar Entrevista
```http
GET /api/entrevistas/1
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
{
  "id": "1",
  "candidato_id": "1",
  "vaga_id": "1",
  "curriculo_id": "123",
  "status": "concluida",
  "data_hora": "2024-10-08T14:00:00Z",
  "perguntas": [
    {
      "id": "1",
      "texto": "Explique o conceito de idempotência em APIs RESTful",
      "categoria": "tecnica",
      "resposta": "Idempotência significa...",
      "pontuacao": 8
    }
  ],
  "avaliacao_final": {
    "pontuacao_geral": 85,
    "recomendacao": "contratar"
  }
}
```

### Gerar Perguntas para Entrevista
```http
POST /api/entrevistas/1/perguntas?qtd=5
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
[
  {
    "categoria": "tecnica",
    "texto": "Explique o conceito de idempotência em APIs RESTful"
  },
  {
    "categoria": "tecnica",
    "texto": "Como você estrutura testes automatizados?"
  },
  {
    "categoria": "comportamental",
    "texto": "Conte sobre um projeto desafiador que você liderou"
  }
]
```

### Avaliar Resposta
```http
POST /api/entrevistas/1/avaliar
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "pergunta_id": "1",
  "resposta": "Idempotência significa que uma operação pode ser repetida múltiplas vezes sem causar efeitos colaterais adicionais."
}
```

**Resposta:**
```json
{
  "pontuacao": 8,
  "feedback": "Resposta clara e objetiva, demonstrando conhecimento sólido.",
  "insights": [
    "Candidato entende o conceito",
    "Poderia dar mais exemplos práticos"
  ]
}
```

### Finalizar Entrevista e Gerar Relatório
```http
POST /api/entrevistas/1/finalizar
Authorization: Bearer <TOKEN>
Content-Type: application/json

{
  "observacoes": "Candidato demonstrou excelente conhecimento técnico"
}
```

**Resposta:**
```json
{
  "relatorio_id": "456",
  "pontuacao_geral": 85,
  "recomendacao": "contratar",
  "relatorio_url": "/api/relatorios/456"
}
```

## 📊 Dashboard

### Obter Estatísticas
```http
GET /api/dashboard
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
{
  "vagas": 8,
  "candidatos": 142,
  "entrevistas": 23,
  "aprovados": 12,
  "estatisticas": {
    "curriculos_recebidos": 142,
    "triagem_inicial": 68,
    "entrevistas_realizadas": 23,
    "aprovados": 12
  },
  "atividades_recentes": [
    {
      "tipo": "curriculo",
      "candidato": "João Silva",
      "acao": "enviou currículo para",
      "vaga": "Desenvolvedor Full Stack",
      "tempo": "5 min atrás"
    }
  ]
}
```

## 📚 Histórico

### Listar Histórico de Entrevistas
```http
GET /api/historico
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
[
  {
    "id": "1",
    "candidato": "João Silva",
    "vaga": "Desenvolvedor Full Stack",
    "data": "2024-10-08",
    "status": "Aprovado",
    "pontuacao": 85
  },
  {
    "id": "2",
    "candidato": "Maria Santos",
    "vaga": "UX/UI Designer",
    "data": "2024-10-05",
    "status": "Em Análise",
    "pontuacao": 78
  }
]
```

## 📋 Relatórios

### Buscar Relatório
```http
GET /api/relatorios/456
Authorization: Bearer <TOKEN>
```

**Resposta:**
```json
{
  "id": "456",
  "entrevista_id": "1",
  "candidato_nome": "João Silva",
  "vaga_titulo": "Desenvolvedor Full Stack",
  "pontuacao_geral": 85,
  "recomendacao": "contratar",
  "analise_detalhada": {
    "conhecimento_tecnico": 88,
    "experiencia_pratica": 85,
    "comunicacao": 82,
    "resolucao_problemas": 90,
    "fit_cultural": 78
  },
  "pontos_fortes": [
    "Excelente domínio de tecnologias",
    "Raciocínio lógico sólido"
  ],
  "pontos_melhoria": [
    "Aprofundar SQL",
    "Metodologias ágeis"
  ],
  "gerado_em": "2024-10-08T16:00:00Z"
}
```

### Exportar Relatório como PDF
```http
GET /api/relatorios/456/pdf
Authorization: Bearer <TOKEN>
```

**Resposta:** Arquivo PDF

## ⚠️ Tratamento de Erros

### Erro de Autenticação
```json
{
  "erro": "Token inválido ou expirado",
  "status": 401
}
```

### Erro de Validação
```json
{
  "erro": "Campos obrigatórios: titulo, descricao, requisitos",
  "status": 400
}
```

### Erro de Não Encontrado
```json
{
  "erro": "Vaga não encontrada",
  "status": 404
}
```

### Erro do Servidor
```json
{
  "erro": "Erro interno do servidor",
  "status": 500,
  "detalhes": "Mensagem de erro específica"
}
```

## 🔧 Paginação (Futuro)

```http
GET /api/candidatos?page=1&limit=10&sort=criado_em&order=desc
```

## 🔍 Filtros (Futuro)

```http
GET /api/vagas?status=aberta&nivel=pleno&tecnologias=React,Node.js
```

## 📡 WebSocket (Futuro)

```javascript
// Conectar ao WebSocket
const ws = new WebSocket('ws://localhost:4000/ws');

// Receber atualizações em tempo real
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Nova atualização:', data);
};

// Exemplo de evento
{
  "tipo": "nova_candidatura",
  "candidato": "João Silva",
  "vaga": "Desenvolvedor Full Stack",
  "timestamp": "2025-10-12T10:45:00Z"
}
```

---

**Nota:** Todos os exemplos usam dados mockados quando o banco de dados não está configurado. As respostas reais podem variar ligeiramente.
