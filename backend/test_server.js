// Script para testar inicialização do servidor
console.log('1. Iniciando teste...');

try {
  console.log('2. Carregando dotenv...');
  require('dotenv').config();
  
  console.log('3. Carregando express...');
  const express = require('express');
  const app = express();
  
  console.log('4. Configurando JSON middleware...');
  app.use(express.json());
  
  console.log('5. Carregando CORS...');
  const cors = require('cors');
  app.use(cors({ origin: true }));
  
  console.log('6. Carregando rotas da API...');
  const apiRoutes = require('./src/api');
  
  console.log('7. Montando rotas...');
  app.use('/api', apiRoutes);
  
  console.log('8. Configurando rota raiz...');
  app.get('/', (req, res) => {
    res.send('Bem-vindo à API do TalentMatchIA!');
  });
  
  console.log('9. Iniciando servidor...');
  const PORT = process.env.PORT || 4000;
  app.listen(PORT, () => {
    console.log(`✅ Servidor rodando na porta ${PORT}`);
  });
  
} catch (error) {
  console.error('❌ ERRO:', error);
  console.error('Stack:', error.stack);
  process.exit(1);
}
