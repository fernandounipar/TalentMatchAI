# Migração de GROQ para OpenRouter - Concluída ✅

## Resumo das Alterações

A migração do sistema de IA de **GROQ** para **OpenRouter** foi concluída com sucesso.

## Arquivos Excluídos

Os seguintes arquivos relacionados ao GROQ foram removidos:

1. ❌ `backend/src/servicos/groqService.js`
2. ❌ `backend/scripts/test_groq.js`
3. ❌ `backend/scripts/test_groq_requisitos.js`
4. ❌ `backend/scripts/setup_groq_interactive.js`

## Arquivos Criados

1. ✅ `backend/src/servicos/openRouterService.js` - Novo serviço de IA
2. ✅ `backend/scripts/test_openrouter.js` - Script de teste

## Arquivos Modificados

1. ✅ `backend/src/servicos/iaService.js` - Atualizado para usar OpenRouter
2. ✅ `backend/.env` - Removida GROQ_API_KEY, adicionada OPENROUTER_MODEL

## Configuração no .env

```env
# OpenRouter Configuration
OPENROUTER_API_KEY=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
OPENROUTER_MODEL=x-ai/grok-4.1-fast
```

## Funcionalidades do OpenRouter Service

### 1. Análise de Currículo
```javascript
const analise = await openRouterService.analisarCurriculo(textoCurriculo, vaga);
```

Retorna:
- `skills`: Array de habilidades detectadas
- `experiencia`: Descrição resumida da experiência
- `senioridade`: Nível (Júnior/Pleno/Sênior/Especialista)
- `aderenciaVaga`: Score de 0 a 100 (quando vaga fornecida)
- `pontosFortesVaga`: Array de pontos fortes
- `pontosFracosVaga`: Array de pontos fracos

### 2. Geração de Perguntas de Entrevista
```javascript
const perguntas = await openRouterService.gerarPerguntasEntrevista(vaga, curriculo);
```

Retorna array de objetos:
- `texto`: A pergunta
- `categoria`: Técnica/Comportamental/Situacional/Cultural
- `peso`: 1-5

### 3. Avaliação de Resposta
```javascript
const avaliacao = await openRouterService.avaliarResposta(pergunta, resposta);
```

Retorna:
- `nota`: 1-10
- `feedback`: Feedback construtivo
- `pontosFortesResposta`: Array de pontos fortes
- `pontosMelhoria`: Array de pontos de melhoria

## Integração com iaService.js

O `iaService.js` mantém compatibilidade com OpenAI e adiciona **fallback automático** para OpenRouter:

### Cenários de Fallback:

1. **OpenAI não configurada** → Usa OpenRouter automaticamente
2. **OpenAI com erro 429 (quota exceeded)** → Usa OpenRouter como backup
3. **OpenRouter também falha** → Retorna análise indisponível

## Vantagens do OpenRouter

✅ **Acesso a múltiplos modelos de IA:**
- x-ai/grok-4.1-fast (rápido e eficiente)
- anthropic/claude-3.5-sonnet
- openai/gpt-4o
- E muitos outros...

✅ **API única** para todos os modelos

✅ **Créditos iniciais gratuitos**

✅ **Preços competitivos**

✅ **Suporte a reasoning** (raciocínio detalhado do modelo)

## Como Testar

Execute o script de teste:

```bash
node scripts/test_openrouter.js
```

Testes realizados:
1. ✅ Formato da chave
2. ✅ Conexão básica
3. ✅ Análise de currículo

## Modelos Recomendados

### Para Desenvolvimento/Testes:
- `x-ai/grok-4.1-fast` (rápido e econômico) ⭐ **Padrão atual**

### Para Produção:
- `anthropic/claude-3.5-sonnet` (mais preciso)
- `openai/gpt-4o` (compatível com OpenAI)

### Para Altíssima Performance:
- `x-ai/grok-2-1212` (modelo premium)

## Como Trocar de Modelo

Edite o `.env`:

```env
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
```

Ou via código:

```javascript
const resposta = await openRouterService.chamarOpenRouter(
  mensagens,
  { model: 'anthropic/claude-3.5-sonnet' }
);
```

## Estrutura do Código

### openRouterService.js
```
├── chamarOpenRouter()        # Função base de comunicação
├── analisarCurriculo()       # Análise de currículos
├── gerarPerguntasEntrevista() # Geração de perguntas
└── avaliarResposta()         # Avaliação de respostas
```

### Características Técnicas:
- ✅ Uso de HTTPS nativo (sem dependências externas)
- ✅ Timeout de 60 segundos (modelos podem demorar)
- ✅ Tratamento de erros específicos (401, 402, 429, timeout)
- ✅ Suporte a reasoning details
- ✅ Parsing automático de JSON com fallback

## Status de Implementação

| Funcionalidade | Status |
|----------------|--------|
| Análise de Currículo | ✅ Testado e funcionando |
| Geração de Perguntas | ✅ Implementado |
| Avaliação de Resposta | ✅ Implementado |
| Fallback OpenAI → OpenRouter | ✅ Implementado |
| Script de Teste | ✅ Criado e testado |
| Documentação | ✅ Completa |

## Próximos Passos

1. ✅ Migração concluída
2. ⏳ Testar em ambiente de produção
3. ⏳ Monitorar custos e performance
4. ⏳ Ajustar modelo se necessário

## Suporte e Links

- 📚 Documentação OpenRouter: https://openrouter.ai/docs
- 🔑 Gerenciar Keys: https://openrouter.ai/keys
- 💳 Gerenciar Créditos: https://openrouter.ai/credits
- 🤖 Explorar Modelos: https://openrouter.ai/models

---

**Data da Migração:** 20/11/2025  
**Status:** ✅ CONCLUÍDA E TESTADA
