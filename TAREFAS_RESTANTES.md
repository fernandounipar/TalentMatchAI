# 📋 TAREFAS RESTANTES - TalentMatchIA MVP

**Data:** 26/11/2025  
**Status Geral:** 🟢 98% Completo  
**Próxima Demo:** 01/12/2025

---

## 🔴 ALTA PRIORIDADE (Bloqueiam Demo)

### ALEX - Frontend (4h restantes)

#### 1. Melhorar Tratamento de Erros em 3 Telas
**Prazo:** 26/11 (tarde)  
**Tempo:** 2h

**Arquivos a modificar:**
- `frontend/lib/telas/vagas_tela.dart`
- `frontend/lib/telas/candidatos_tela.dart`
- `frontend/lib/telas/entrevistas_tela.dart`

**Padrão a implementar:**
```dart
// 1. Adicionar campo de erro no State
String? _erro;

// 2. Atualizar método de carregamento
try {
  // ... lógica existente
} catch (e) {
  if (mounted) {
    setState(() {
      _carregando = false;
      _erro = 'Falha ao carregar: ${e.toString()}';
    });
  }
}

// 3. Adicionar widget de erro no build
if (_erro != null) {
  return Column(
    children: [
      _buildErrorBanner(),
      // ... resto do conteúdo
    ],
  );
}

// 4. Criar método _buildErrorBanner()
Widget _buildErrorBanner() {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.shade300),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _erro!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
        TMButton(
          'Tentar Novamente',
          icon: Icons.refresh,
          onPressed: () {
            setState(() => _erro = null);
            _carregar(); // método de carregamento
          },
        ),
      ],
    ),
  );
}
```

**Critérios de Aceite:**
- [ ] Banner vermelho aparece quando há erro
- [ ] Mensagem de erro é clara e contextual
- [ ] Botão "Tentar Novamente" recarrega os dados
- [ ] Erro desaparece após reload bem-sucedido
- [ ] Loading state é exibido durante retry

---

#### 2. Testar Fluxo Completo de Relatórios
**Prazo:** 26/11 (tarde)  
**Tempo:** 1h

**Cenários a testar:**
1. Login → Dashboard → Entrevistas
2. Selecionar entrevista → Ver relatório
3. Verificar dados:
   - Nome do candidato correto
   - Título da vaga correto
   - Data de geração
   - Recomendação (Aprovar/Considerar/Rejeitar)
   - Rating (0-5)
   - Critérios com notas
   - Síntese textual

**Checklist:**
- [ ] Relatório carrega dados reais do backend
- [ ] Mapeamento de campos está correto
- [ ] Formatação de data está em PT-BR
- [ ] Recomendação traduzida corretamente
- [ ] Score convertido de 0-100 para 0-5
- [ ] Critérios são exibidos corretamente
- [ ] Fallback funciona se não houver critérios
- [ ] Tratamento de erro resiliente (não quebra app)

---

#### 3. Validar Upload de Currículo
**Prazo:** 27/11  
**Tempo:** 1h

**Fluxo a testar:**
1. Login → Upload de Currículo
2. Selecionar arquivo PDF/TXT/DOCX
3. Preencher dados do candidato (opcional)
4. Vincular a vaga (opcional)
5. Enviar

**Checklist:**
- [ ] Validação de tamanho funciona (max 5MB)
- [ ] Validação de tipo funciona (PDF/TXT/DOCX)
- [ ] Barra de progresso aparece
- [ ] Estados: idle → uploading → parsing → analyzing → complete
- [ ] Resposta do backend é exibida corretamente
- [ ] Análise da IA é mostrada
- [ ] Mensagens de erro são claras

---

### EMMA - Gerente de Produto (6h restantes)

#### 1. Expandir Roteiro UAT
**Prazo:** 27/11  
**Tempo:** 3h

**Estrutura do documento:**
```markdown
# Roteiro UAT - TalentMatchIA

## RF1 - Upload de Currículos
### Cenário 1: Upload bem-sucedido
- **Pré-condição:** ...
- **Passos:** ...
- **Resultado esperado:** ...
- **Critério de aprovação:** ...

### Cenário 2: Upload com arquivo inválido
...

### Cenário 3: Upload sem vaga vinculada
...

## RF2 - Gerenciamento de Vagas
...

## RF7 - Relatórios
...
```

**Incluir:**
- [ ] Casos de sucesso (happy path)
- [ ] Casos de erro (validações)
- [ ] Edge cases (limites, dados vazios)
- [ ] Testes de permissão (USER vs ADMIN)
- [ ] Testes cross-browser (Chrome, Firefox, Edge)

---

#### 2. Executar UAT Completo
**Prazo:** 27/11  
**Tempo:** 3h

**Ambiente:**
- Backend rodando em `http://localhost:3000`
- Frontend rodando em `http://localhost:XXXXX`
- Banco com dados de teste (seed do David)

**Executar testes de:**
- [ ] RF1 - Upload e análise de currículos
- [ ] RF2 - Cadastro de vagas
- [ ] RF3 - Geração de perguntas
- [ ] RF7 - Relatórios detalhados
- [ ] RF8 - Histórico de entrevistas
- [ ] RF9 - Dashboard
- [ ] RF10 - Gerenciamento de usuários

**Para cada RF:**
- [ ] Documentar bugs encontrados
- [ ] Classificar severidade (Crítica/Alta/Média/Baixa)
- [ ] Criar issues no backlog
- [ ] Validar critérios de aceite

---

### DAVID - Analista de Dados (4h restantes)

#### 1. Validar Função Dashboard
**Prazo:** 26/11 (tarde)  
**Tempo:** 1h

**Executar query:**
```sql
-- Conectar ao banco
psql -U postgres -d talentmatchia_dev

-- Executar função
SELECT * FROM get_dashboard_overview('COMPANY_ID_AQUI');
```

**Validar:**
- [ ] Query executa em menos de 2 segundos
- [ ] Retorna campos: vagas, curriculos, entrevistas, relatorios, candidatos
- [ ] Números batem com contagens reais das tabelas
- [ ] Multi-tenant: só conta registros da company específica
- [ ] Sem erros de SQL

**Se houver problemas:**
- Adicionar índices necessários
- Otimizar queries
- Atualizar função conforme necessário

---

#### 2. Preparar Seed de Dados para Demo
**Prazo:** 27/11  
**Tempo:** 3h

**Criar script:** `backend/scripts/seed_demo.js`

**Dados a inserir:**

1. **Empresa:**
   - Nome: "Tech Recrutadora LTDA"
   - CNPJ: 12345678000195

2. **Usuários:**
   - Admin: admin@techrecrutadora.com / senha123
   - Recrutador: recrutador@techrecrutadora.com / senha123

3. **Vagas (5):**
   - Desenvolvedor Full Stack Pleno
   - Designer UX Sênior
   - Engenheiro de Dados Júnior
   - Product Manager Pleno
   - DevOps Engineer Sênior

4. **Candidatos (10):**
   - Nomes, emails, telefones realistas
   - Skills variadas (JavaScript, Python, React, Flutter, SQL, AWS, etc.)
   - Alguns com GitHub URLs

5. **Currículos (5):**
   - 5 candidatos com currículos analisados
   - Vinculados a vagas diferentes
   - Status: pending, reviewed, accepted, rejected

6. **Entrevistas (3):**
   - 3 entrevistas completas
   - Com perguntas geradas
   - Com respostas simuladas
   - Com relatórios finalizados

**Script base:**
```javascript
const db = require('../src/config/database');

async function seed() {
  const client = await db.connect();
  
  try {
    await client.query('BEGIN');
    
    // 1. Criar empresa
    const company = await client.query(`
      INSERT INTO companies (name, document_type, document, created_at)
      VALUES ($1, $2, $3, NOW())
      RETURNING id
    `, ['Tech Recrutadora LTDA', 'CNPJ', '12345678000195']);
    
    const companyId = company.rows[0].id;
    
    // 2. Criar usuários
    // ... (usar bcrypt para senhas)
    
    // 3. Criar vagas
    // ...
    
    // 4. Criar candidatos
    // ...
    
    // 5. Criar currículos
    // ...
    
    // 6. Criar entrevistas
    // ...
    
    await client.query('COMMIT');
    console.log('✅ Seed completo!');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erro no seed:', error);
  } finally {
    client.release();
  }
}

seed();
```

**Executar:**
```bash
node backend/scripts/seed_demo.js
```

**Validar:**
- [ ] Empresa criada
- [ ] 2 usuários criados
- [ ] 5 vagas criadas
- [ ] 10 candidatos criados
- [ ] 5 currículos criados
- [ ] 3 entrevistas criadas com relatórios

---

## 🟡 MÉDIA PRIORIDADE (Melhoram UX)

### BOB - Backend (4h)

#### 1. Revisar Segurança Básica
**Prazo:** 28/11  
**Tempo:** 2h

**Checklist:**
- [ ] Helmet configurado
- [ ] Rate limiting em rotas sensíveis
- [ ] CORS configurado corretamente
- [ ] Validação de inputs em todos os endpoints
- [ ] Sanitização de queries SQL (já usando prepared statements)
- [ ] Logs de auditoria funcionando

---

#### 2. Validar CRUD Completo de Usuários
**Prazo:** 28/11  
**Tempo:** 1h

**Testar endpoints:**
- [ ] `GET /api/usuarios` - Listar usuários da empresa
- [ ] `POST /api/usuarios` - Criar usuário
- [ ] `PUT /api/usuarios/:id` - Atualizar usuário
- [ ] `DELETE /api/usuarios/:id` - Desativar usuário

**Validar payloads e respostas:**
- [ ] Envelope `{data, meta}` consistente
- [ ] Campos obrigatórios validados
- [ ] Permissões verificadas (ADMIN only)
- [ ] Multi-tenant isolado (company_id)

---

### ALEX - Frontend (6h)

#### 1. Expandir Tela de Usuários
**Prazo:** 28/11  
**Tempo:** 3h

**Adicionar em `usuarios_admin_tela.dart`:**

1. **Tabela de usuários existentes:**
```dart
Future<List<Map<String, dynamic>>> _listarUsuarios() async {
  final resp = await widget.api.http.get(
    Uri.parse('${widget.api.baseUrl}/api/usuarios'),
    headers: widget.api._headers(),
  );
  return jsonDecode(resp.body)['data'];
}

Widget _buildUsuariosTable() {
  return DataTable(
    columns: [
      DataColumn(label: Text('Nome')),
      DataColumn(label: Text('Email')),
      DataColumn(label: Text('Perfil')),
      DataColumn(label: Text('Status')),
      DataColumn(label: Text('Ações')),
    ],
    rows: _usuarios.map((u) => DataRow(cells: [
      DataCell(Text(u['full_name'])),
      DataCell(Text(u['email'])),
      DataCell(TMChip.role(u['role'])),
      DataCell(TMChip.status(u['is_active'] ? 'Ativo' : 'Inativo')),
      DataCell(Row(children: [
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => _editarUsuario(u),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _desativarUsuario(u['id']),
        ),
      ])),
    ])).toList(),
  );
}
```

2. **Modal de edição:**
- Campos: nome, email, perfil, telefone, cargo
- Validação de formulário
- Chamada a `PUT /api/usuarios/:id`

3. **Confirmação de exclusão:**
- Dialog com confirmação
- Chamada a `DELETE /api/usuarios/:id`

---

#### 2. Implementar Guards de Rota
**Prazo:** 29/11  
**Tempo:** 2h

**Criar:** `frontend/lib/componentes/route_guard.dart`

```dart
class RouteGuard extends StatelessWidget {
  final Widget child;
  final bool requiresCompany;
  final List<String> allowedRoles;

  const RouteGuard({
    required this.child,
    this.requiresCompany = false,
    this.allowedRoles = const [],
  });

  @override
  Widget build(BuildContext context) {
    final userData = // buscar do context ou state management
    
    // Verificar se tem company
    if (requiresCompany && userData['company'] == null) {
      return OnboardingEmpresaTela();
    }
    
    // Verificar role
    if (allowedRoles.isNotEmpty && 
        !allowedRoles.contains(userData['role'])) {
      return AcessoNegadoTela();
    }
    
    return child;
  }
}
```

**Aplicar em rotas:**
```dart
'/usuarios': (context) => RouteGuard(
  requiresCompany: true,
  allowedRoles: ['ADMIN', 'SUPER_ADMIN'],
  child: UsuariosAdminTela(api: api),
),
```

---

#### 3. Padronizar Loading States
**Prazo:** 29/11  
**Tempo:** 1h

**Criar:** `frontend/lib/componentes/skeleton_loader.dart`

**Substituir spinners por skeletons em:**
- `vagas_tela.dart` - Grid de cards
- `candidatos_tela.dart` - Lista de candidatos
- `entrevistas_tela.dart` - Lista de entrevistas
- `dashboard_tela.dart` - KPIs

---

## 🟢 BAIXA PRIORIDADE (Pós-MVP)

### ALEX - Frontend (16h)

#### 1. Criar Tela de Aplicações (Kanban)
**Prazo:** Pós-MVP  
**Tempo:** 8h

**Recursos:**
- Kanban board com drag & drop
- Estágios: Triagem → Entrevista → Oferta → Contratado
- Cards com candidato + vaga
- Histórico de movimentações

**Endpoints a consumir:**
- `GET /api/applications`
- `POST /api/applications/:id/move`
- `GET /api/applications/:id/history`

---

#### 2. Integrar GitHub em Candidatos
**Prazo:** Pós-MVP  
**Tempo:** 3h

**Adicionar seção em detalhes do candidato:**
```dart
if (candidato.githubUrl != null) {
  FutureBuilder<Map<String, dynamic>>(
    future: widget.api.obterGitHubProfile(candidato.id),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final gh = snapshot.data!;
        return Column(children: [
          Text('Repos: ${gh['public_repos']}'),
          Text('Followers: ${gh['followers']}'),
          Text('Linguagens: ${gh['languages'].join(', ')}'),
        ]);
      }
      return CircularProgressIndicator();
    },
  );
}
```

---

### IRIS - Pesquisadora (12h)

#### 1. Avaliar Token Storage
**Prazo:** Pós-MVP  
**Tempo:** 4h

**Pesquisar:**
- `flutter_secure_storage` para web
- Fallback via cookies com httpOnly
- Refresh token rotation
- CSRF protection

**Entregar:** Documento com recomendações

---

#### 2. Pesquisar GitHub Integration
**Prazo:** Pós-MVP  
**Tempo:** 4h

**Pesquisar:**
- Rate limits da API do GitHub
- Estratégias de caching
- Campos úteis além dos básicos
- Autenticação via OAuth (futuro)

**Entregar:** Documento com recomendações

---

#### 3. Mapear LGPD/Conformidade
**Prazo:** Pós-MVP  
**Tempo:** 4h

**Documentar:**
- Textos de consentimento necessários
- Políticas de retenção de dados
- Direito ao esquecimento (implementação)
- Anonimização de dados sensíveis
- Relatórios de auditoria

**Entregar:** Checklist de conformidade

---

## 📅 CRONOGRAMA

### Terça 26/11 (Hoje)
- **Alex:** Tratamento de erros (2h) + Teste relatórios (1h)
- **David:** Validar função dashboard (1h)

### Quarta 27/11
- **Emma:** Expandir UAT (3h) + Executar UAT (3h)
- **Alex:** Validar upload (1h)
- **David:** Seed de dados (3h)

### Quinta 28/11
- **Alex:** Expandir tela usuários (3h)
- **Bob:** Segurança + CRUD usuários (3h)
- **Emma:** Documentar bugs (2h)

### Sexta 29/11
- **Alex:** Guards de rota (2h) + Skeletons (1h)
- **Bob:** Correções de bugs (4h)
- **David:** Ajustes no seed (1h)

### Sábado-Domingo 30/11-01/12
- Preparação final
- Revisão de documentação
- Ensaio da demo

### Segunda 01/12
- **DEMO INTERNA** 🎉

---

## 🎯 CRITÉRIOS DE APROVAÇÃO DA DEMO

### Funcionalidades Obrigatórias

- [ ] Login funciona
- [ ] Dashboard exibe KPIs reais
- [ ] Criar vaga funciona
- [ ] Upload de currículo funciona
- [ ] Análise de IA aparece
- [ ] Entrevista assistida funciona
- [ ] Relatório é gerado
- [ ] Relatórios exibem dados reais
- [ ] Histórico mostra atividades
- [ ] Criar usuário funciona (ADMIN)

### UX Mínima

- [ ] Sem erros no console
- [ ] Sem telas quebradas
- [ ] Loading states em todas as ações
- [ ] Mensagens de erro claras
- [ ] Responsivo (desktop e tablet)
- [ ] Textos em PT-BR

### Performance

- [ ] Dashboard carrega em < 2s
- [ ] Análise de currículo < 10s (RNF1)
- [ ] Navegação fluida (sem lag)

---

**Documento criado por:** Mike (Líder de Equipe)  
**Última atualização:** 26/11/2025  
**Próxima revisão:** 27/11/2025
