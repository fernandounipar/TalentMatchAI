# 🚀 Guia de Execução - TalentMatchIA

## Início Rápido (5 minutos)

### Opção 1: Executar com Dados Mockados (Recomendado para Testes)

Esta é a forma mais rápida de testar o sistema sem precisar configurar banco de dados.

#### Backend

```powershell
# 1. Navegue até a pasta do backend
cd backend

# 2. Instale as dependências
npm install

# 3. Inicie o servidor (usará dados mockados automaticamente)
npm run dev
```

O backend estará rodando em `http://localhost:4000`

#### Frontend

```powershell
# 1. Em outro terminal, navegue até a pasta do frontend
cd frontend

# 2. Instale as dependências do Flutter
flutter pub get

# 3. Execute no navegador Chrome
flutter run -d chrome
```

A aplicação web abrirá automaticamente no Chrome.

### Opção 2: Executar com Banco de Dados PostgreSQL

#### Pré-requisitos
- PostgreSQL 14+ instalado e rodando

#### Configuração do Backend

```powershell
# 1. Navegue até a pasta do backend
cd backend

# 2. Instale as dependências
npm install

# 3. Crie o arquivo .env (copie do .env.example)
copy .env.example .env

# 4. Edite o .env com suas configurações
notepad .env
```

Exemplo de `.env`:
```env
PORT=4000
DATABASE_URL=postgresql://postgres:sua_senha@localhost:5432/talentmatchia
JWT_SECRET=sua_chave_secreta_aqui
OPENAI_API_KEY=sk-sua_chave_openai  # Opcional
```

```powershell
# 5. Execute as migrações do banco (se disponíveis)
npm run migrate  # ou crie as tabelas manualmente

# 6. Inicie o servidor
npm run dev
```

#### Frontend (mesmo processo)

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

## 📱 Executar em Diferentes Plataformas

### Web (Chrome)
```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

### Web (Edge)
```powershell
flutter run -d edge --dart-define=API_BASE_URL=http://localhost:4000
```

### Android (Emulador ou Dispositivo)
```powershell
# Certifique-se de que um emulador está rodando ou dispositivo conectado
flutter devices  # Listar dispositivos disponíveis
flutter run      # Executar no primeiro dispositivo disponível
```

### iOS (apenas macOS)
```powershell
flutter run -d "iPhone 14"  # ou outro simulador
```

### Desktop Windows
```powershell
flutter run -d windows
```

## 🔧 Solução de Problemas

### Backend não inicia

**Problema**: Erro de conexão com banco de dados
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```

**Solução**: O sistema automaticamente usa dados mockados quando o banco não está disponível. Você pode ignorar este erro e continuar usando.

Ou configure o PostgreSQL:
1. Instale PostgreSQL
2. Crie um banco de dados: `CREATE DATABASE talentmatchia;`
3. Configure o `DATABASE_URL` no `.env`

---

**Problema**: Porta 4000 já em uso
```
Error: listen EADDRINUSE :::4000
```

**Solução**: 
```powershell
# Mude a porta no .env
PORT=4001

# Ou mate o processo na porta 4000
# Windows:
netstat -ano | findstr :4000
taskkill /PID <PID> /F
```

### Frontend não inicia

**Problema**: Flutter não encontrado
```
'flutter' is not recognized as an internal or external command
```

**Solução**: 
1. Instale Flutter: https://docs.flutter.dev/get-started/install
2. Adicione Flutter ao PATH do sistema
3. Execute `flutter doctor` para verificar instalação

---

**Problema**: Erro ao conectar com API
```
Exception: Failed host lookup: 'localhost'
```

**Solução**:
```powershell
# Execute com a URL correta da API
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000

# Se estiver testando em dispositivo físico, use o IP da máquina:
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:4000
```

---

**Problema**: Chrome não abre automaticamente

**Solução**:
```powershell
# Especifique o Chrome explicitamente
flutter run -d chrome

# Ou liste os dispositivos disponíveis
flutter devices
flutter run -d <ID-do-dispositivo>
```

## 📝 Scripts Úteis

### Backend

```powershell
# Desenvolvimento com hot reload
npm run dev

# Produção
npm start

# Testes (quando implementados)
npm test

# Verificar código
npm run lint
```

### Frontend

```powershell
# Executar no Chrome
flutter run -d chrome

# Build para produção (web)
flutter build web

# Build para Android
flutter build apk

# Build para Windows
flutter build windows

# Limpar cache e rebuild
flutter clean
flutter pub get
flutter run

# Verificar problemas
flutter doctor

# Análise de código
flutter analyze

# Formatar código
dart format .
```

## 🧪 Testar a API

### Usando cURL (PowerShell)

```powershell
# Login (retorna JWT token)
curl -X POST http://localhost:4000/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"teste@email.com\",\"senha\":\"123456\"}'

# Listar vagas
curl http://localhost:4000/api/vagas `
  -H "Authorization: Bearer <SEU_TOKEN>"

# Dashboard
curl http://localhost:4000/api/dashboard `
  -H "Authorization: Bearer <SEU_TOKEN>"

# Candidatos
curl http://localhost:4000/api/candidatos `
  -H "Authorization: Bearer <SEU_TOKEN>"
```

### Usando Postman/Insomnia

Importe a coleção OpenAPI: `openapi/talentmatchia.yaml`

## 🔑 Credenciais de Teste (Dados Mockados)

### Login
- **Email**: qualquer email (ex: `admin@talentmatch.com`)
- **Senha**: qualquer senha (ex: `123456`)

*Nota: Em modo mockado, qualquer combinação de email/senha funcionará*

## 📊 Dados de Exemplo Disponíveis

Quando usar dados mockados, você terá acesso a:

- **8 Vagas** pré-cadastradas
- **142 Candidatos** fictícios
- **23 Entrevistas** de exemplo
- **12 Aprovações** simuladas
- **Histórico** completo de processos
- **Relatórios** detalhados

## 🌐 URLs Importantes

- **Frontend Web**: http://localhost:3000 (ou porta configurada pelo Flutter)
- **Backend API**: http://localhost:4000
- **Documentação API**: http://localhost:4000/api-docs (se configurado)

## 💡 Dicas

1. **Desenvolvimento Frontend**: Use hot reload do Flutter (`r` no terminal para reload, `R` para restart)

2. **Desenvolvimento Backend**: O nodemon faz reload automático ao salvar arquivos

3. **Debug**: 
   - Frontend: Use Flutter DevTools
   - Backend: Use `console.log()` ou VSCode debugger

4. **Performance**: 
   - Execute build de produção para testes de performance
   - `flutter build web --release`

5. **Múltiplos Testes**: 
   - Abra múltiplas janelas do navegador para simular usuários diferentes

## 🎯 Próximos Passos Após Executar

1. ✅ Faça login na plataforma
2. ✅ Explore o Dashboard
3. ✅ Crie uma nova vaga
4. ✅ Faça upload de um currículo fictício
5. ✅ Realize uma entrevista assistida
6. ✅ Gere um relatório final
7. ✅ Consulte o histórico

---

**Precisa de ajuda?** 
- Verifique o `README.md` para documentação completa
- Consulte `IMPLEMENTACOES.md` para detalhes técnicos
- Abra uma issue no GitHub
