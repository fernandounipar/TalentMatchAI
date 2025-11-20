# 🔑 Como Configurar a OpenAI API Key

## Passo a Passo

### 1️⃣ Criar Conta na OpenAI

1. Acesse: https://platform.openai.com/signup
2. Crie uma conta (pode usar conta do Google/GitHub)
3. Verifique seu email

### 2️⃣ Gerar API Key

1. Acesse: https://platform.openai.com/api-keys
2. Clique em **"+ Create new secret key"**
3. Dê um nome (ex: "TalentMatchAI Dev")
4. Copie a chave (começa com `sk-proj-...`)
   ⚠️ **IMPORTANTE:** Você só verá a chave UMA VEZ! Copie e guarde bem.

### 3️⃣ Configurar no Projeto

1. Abra o arquivo `.env` na pasta `backend/`
2. Cole a chave na linha `OPENAI_API_KEY`:

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

3. Salve o arquivo
4. Reinicie o servidor backend

### 4️⃣ Testar a Conexão

Execute os scripts de teste na ordem:

```bash
# Teste 1: Testar se a chave funciona
node scripts/test_openai.js

# Teste 2: Testar análise de currículo
node scripts/test_analise_curriculo.js
```

---

## 💰 Custos e Créditos

### Créditos Gratuitos
- Novos usuários ganham **$5 de crédito grátis**
- Válido por **3 meses** após criação da conta
- Suficiente para ~2.500 análises de currículo (aproximadamente)

### Preços (após créditos gratuitos)
- **GPT-3.5-turbo:** ~$0.002 por 1K tokens
- **GPT-4:** ~$0.03 por 1K tokens (mais caro, mas mais preciso)

Uma análise de currículo consome ~1.000 tokens = **$0.002** (muito barato!)

### Verificar Saldo
- Acesse: https://platform.openai.com/usage
- Veja quanto já usou e quanto ainda tem disponível

### Adicionar Método de Pagamento (se acabar os créditos)
- Acesse: https://platform.openai.com/account/billing
- Adicione cartão de crédito
- Configure limites de gastos (ex: $10/mês)

---

## ❌ Problemas Comuns

### Erro 401 (Unauthorized)
**Causa:** Chave inválida ou expirada
**Solução:** Gere uma nova chave e atualize o `.env`

### Erro 429 (Rate Limit / Quota Exceeded)
**Causa 1:** Créditos gratuitos acabaram
**Solução:** Adicione método de pagamento

**Causa 2:** Muitas requisições muito rápidas
**Solução:** Aguarde alguns minutos e tente novamente

### Erro 500 (OpenAI API indisponível)
**Causa:** Servidores da OpenAI fora do ar (raro)
**Solução:** Verifique status em https://status.openai.com/

---

## 🔒 Segurança

⚠️ **NUNCA** compartilhe sua API Key!
⚠️ **NUNCA** commite o `.env` no Git!

O arquivo `.gitignore` já está configurado para ignorar o `.env`, mas sempre confira:

```bash
# Verificar se .env está no .gitignore
cat .gitignore | grep ".env"
```

---

## 📚 Documentação Oficial

- API Reference: https://platform.openai.com/docs/api-reference
- Pricing: https://openai.com/pricing
- Rate Limits: https://platform.openai.com/docs/guides/rate-limits

---

## 🧪 Testes Rápidos

Depois de configurar, teste rapidamente:

```bash
# No terminal do backend
cd backend

# Teste 1: Verifica se a chave está configurada
echo $env:OPENAI_API_KEY   # Windows PowerShell
# ou
echo $OPENAI_API_KEY        # Linux/Mac

# Teste 2: Teste completo
node scripts/test_openai.js

# Teste 3: Teste de análise de currículo
node scripts/test_analise_curriculo.js
```

---

## ✅ Checklist Final

- [ ] Conta criada na OpenAI
- [ ] API Key gerada
- [ ] Chave copiada e colada no `.env`
- [ ] Arquivo `.env` salvo
- [ ] Servidor backend reiniciado
- [ ] Teste `test_openai.js` passou
- [ ] Teste `test_analise_curriculo.js` passou
- [ ] Upload de currículo funcionando no app

🎉 Tudo funcionando? Parabéns! Agora você pode analisar currículos com IA!
