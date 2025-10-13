require('dotenv').config();
const express = require('express');
const app = express();
const apiRoutes = require('./src/api');

const PORT = process.env.PORT || 3000;

app.use(express.json());

// Rotas da API
const cors = require('cors');\nconst morgan = require('morgan');\napp.use(cors());\napp.use(morgan('dev'));\napp.use('/api', apiRoutes);

app.get('/', (req, res) => {
  res.send('Bem-vindo Ã  API do TalentMatchIA!');
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

