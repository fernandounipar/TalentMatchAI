# ⚠️ ERRO: OpenAI API - Quota Exceeded (429)

## 🔍 Diagnóstico

Você está recebendo este erro:
```
429 You exceeded your current quota, please check your plan and billing details.
```

**Isso significa:** Seus créditos gratuitos da OpenAI acabaram ou você não tem método de pagamento configurado.

---

## 💰 Soluções

### Opção 1: Adicionar Crédito na OpenAI (Recomendado para Produção)

1. **Verifique seu uso atual:**
   - Acesse: https://platform.openai.com/usage
   - Veja quanto já consumiu

2. **Adicione método de pagamento:**
   - Acesse: https://platform.openai.com/account/billing
   - Clique em "Add payment method"
   - Adicione um cartão de crédito
   - Configure limites de gastos (ex: $10/mês é mais que suficiente)

3. **Custos estimados:**
   - Uma análise de currículo: ~$0.002 (muito barato!)
   - 100 análises: ~$0.20
   - 1000 análises: ~$2.00
   
   💡 Com $10/mês você pode fazer ~5.000 análises!

---

### Opção 2: Criar Nova Conta (Temporário - apenas para testes)

Se você só quer testar rapidamente:

1. Crie uma nova conta da OpenAI com outro email
2. Ganhe mais $5 de crédito grátis
3. Gere uma nova API Key
4. Atualize o `.env` com a nova chave

⚠️ **Atenção:** Isso é apenas para desenvolvimento/testes. Para produção, use a Opção 1.

---

### Opção 3: Usar API Alternativa Gratuita (Groq)

A **Groq** oferece IA gratuita e muito rápida!

#### Passos:

1. **Criar conta na Groq:**
   - Acesse: https://console.groq.com/
   - Faça cadastro (grátis)

2. **Gerar API Key:**
   - Acesse: https://console.groq.com/keys
   - Clique em "Create API Key"
   - Copie a chave (começa com `gsk_...`)

3. **Configurar no projeto:**
   ```env
   # No arquivo .env
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxxx
   ```

4. **Atualizar o código** (vou criar o arquivo para você):

---

## 🧪 Como Testar Cada Opção

### Teste OpenAI:
```bash
node scripts/test_openai.js
```

### Teste Groq (após configurar):
```bash
node scripts/test_groq.js
```

### Teste Análise de Currículo:
```bash
node scripts/test_analise_curriculo.js
```

---

## 📊 Comparação: OpenAI vs Groq

| Característica | OpenAI | Groq |
|---|---|---|
| **Custo** | Pago após $5 grátis | 100% Gratuito |
| **Velocidade** | Rápida | **Muito rápida** |
| **Qualidade** | Excelente | Muito boa |
| **Limite gratuito** | $5 (temporário) | Ilimitado* |
| **Modelos** | GPT-3.5, GPT-4 | Llama 3, Mixtral |
| **Para produção** | ✅ Ideal | ⚠️ Pode ter limites |

\* Groq tem rate limits (requisições por minuto), mas é mais que suficiente para desenvolvimento.

---

## 🎯 Recomendação

**Para este projeto MVP:**
1. Use **Groq** para desenvolvimento/testes (100% grátis)
2. Quando for para produção, migre para **OpenAI** (melhor qualidade, suporte profissional)

**Benefício:** Você desenvolve sem custos e só paga quando tiver usuários reais!

---

## 🚀 Implementação com Groq

Vou criar agora os arquivos necessários para você usar Groq:

1. `backend/src/servicos/groqService.js` - Cliente da API Groq
2. `backend/scripts/test_groq.js` - Teste da conexão
3. Atualizar `iaService.js` para usar Groq como fallback

Execute `test_groq.js` após configurar a chave para ver se funciona!

---

## ✅ Checklist de Resolução

- [ ] Verifiquei meu uso na OpenAI: https://platform.openai.com/usage
- [ ] **Opção A:** Adicionei método de pagamento na OpenAI
  - [ ] Testei com `node scripts/test_openai.js`
- [ ] **Opção B:** Criei conta na Groq
  - [ ] Gerei API Key da Groq
  - [ ] Configurei `GROQ_API_KEY` no `.env`
  - [ ] Testei com `node scripts/test_groq.js`
- [ ] Análise de currículo funcionando no app

---

## 📞 Precisa de Ajuda?

Se ainda estiver com problemas, me avise e eu te ajudo a configurar!
