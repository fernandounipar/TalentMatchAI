// Teste minimalista
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('OK!');
});

const server = app.listen(4000, () => {
  console.log('✅ Servidor minimalista na porta 4000');
});

server.on('error', (e) => {
  console.error('❌ Erro:', e.message);
});

setInterval(() => {
  console.log('⏰ Ainda vivo...');
}, 5000);
