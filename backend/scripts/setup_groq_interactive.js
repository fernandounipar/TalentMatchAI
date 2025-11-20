/**
 * Script interativo para configurar Groq API Key
 * 
 * Uso: node scripts/setup_groq_interactive.js
 */

const readline = require('readline');
const fs = require('fs');
const path = require('path');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('\n🚀 Configuração da Groq API Key\n');
console.log('='.repeat(60));

console.log('\n📝 Primeiro, você precisa obter a chave da Groq:\n');
console.log('1. Acesse: https://console.groq.com/keys');
console.log('2. Faça login ou cadastre-se (grátis)');
console.log('3. Clique em "Create API Key"');
console.log('4. Copie a chave (começa com gsk_...)\n');
console.log('='.repeat(60) + '\n');

rl.question('Cole sua GROQ_API_KEY aqui (ou deixe em branco para cancelar): ', (apiKey) => {
  
  if (!apiKey || !apiKey.trim()) {
    console.log('\n❌ Cancelado. Nenhuma chave foi fornecida.\n');
    rl.close();
    return;
  }

  const key = apiKey.trim();

  // Valida formato básico
  if (!key.startsWith('gsk_')) {
    console.log('\n⚠️  Atenção: A chave não começa com "gsk_"');
    console.log('   Chaves da Groq geralmente começam com "gsk_"');
    console.log('   Mas vou salvar mesmo assim...\n');
  }

  // Lê o arquivo .env
  const envPath = path.join(__dirname, '..', '.env');
  let envContent = '';

  try {
    envContent = fs.readFileSync(envPath, 'utf8');
  } catch (error) {
    console.log('\n❌ Erro ao ler arquivo .env:', error.message);
    rl.close();
    return;
  }

  // Atualiza ou adiciona GROQ_API_KEY
  const lines = envContent.split('\n');
  let found = false;
  const newLines = lines.map(line => {
    if (line.startsWith('GROQ_API_KEY=')) {
      found = true;
      return `GROQ_API_KEY=${key}`;
    }
    return line;
  });

  if (!found) {
    // Adiciona no final se não existir
    newLines.push(`GROQ_API_KEY=${key}`);
  }

  const newContent = newLines.join('\n');

  // Salva o arquivo
  try {
    fs.writeFileSync(envPath, newContent, 'utf8');
    console.log('\n✅ GROQ_API_KEY salva com sucesso no arquivo .env!\n');
    
    // Mostra chave mascarada
    const masked = key.substring(0, 10) + '...' + key.substring(key.length - 4);
    console.log(`🔑 Chave salva: ${masked}`);
    console.log(`   Comprimento: ${key.length} caracteres\n`);
    
    console.log('='.repeat(60));
    console.log('\n🧪 Próximos passos:\n');
    console.log('1. Reinicie o servidor backend:');
    console.log('   npm run dev\n');
    console.log('2. Teste se a Groq está funcionando:');
    console.log('   node scripts/test_groq.js\n');
    console.log('3. Teste análise de currículo:');
    console.log('   node scripts/test_analise_curriculo.js\n');
    console.log('🎉 Depois disso, o upload de currículos funcionará!\n');
    
  } catch (error) {
    console.log('\n❌ Erro ao salvar .env:', error.message);
  }

  rl.close();
});
