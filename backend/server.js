require('dotenv').config();
const express = require('express');
const app = express();
const apiRoutes = require('./src/api');
const path = require('path');
const fs = require('fs');

const PORT = process.env.PORT || 4000;
// CORS: aceita múltiplas origens via env (separadas por vírgula). Por padrão, libera qualquer localhost.
const CORS_ORIGIN = process.env.CORS_ORIGIN; // ex: "http://localhost:5173,http://localhost:8080"
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, 'uploads');

app.use(express.json());

// Rotas da API
const cors = require('cors');
const morgan = require('morgan');
app.use(cors({
  origin: (origin, callback) => {
    // Sem origin (ex.: Postman, curl) → permitir
    if (!origin) return callback(null, true);

    // Libera localhost/127.0.0.1 em qualquer porta no ambiente de dev
    const localhost = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i;
    if (localhost.test(origin)) return callback(null, true);

    // Se CORS_ORIGIN definido: permite se corresponder a qualquer das origens
    if (CORS_ORIGIN) {
      const allowed = CORS_ORIGIN.split(',').map(o => o.trim()).filter(Boolean);
      if (allowed.includes(origin)) return callback(null, true);
    }

    // Caso contrário, bloqueia
    return callback(new Error('CORS: Origin não permitido: ' + origin));
  },
  credentials: false, // tokens via Authorization header; cookies não necessários no Web
}));
app.use(morgan('dev'));
// Arquivos estáticos para download
try { fs.mkdirSync(UPLOAD_DIR, { recursive: true }); } catch {}
app.use('/uploads', express.static(UPLOAD_DIR));

app.use('/api', apiRoutes);

app.get('/', (req, res) => {
  res.send('Bem-vindo à API do TalentMatchIA!');
});

const server = app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

server.on('error', (error) => {
  console.error('❌ Erro ao iniciar servidor:', error.message);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});
