require('dotenv').config();
const express = require('express');
const app = express();
const apiRoutes = require('./src/api');

const PORT = process.env.PORT || 4000;

app.use(express.json());

// Rotas da API
const cors = require('cors');
const morgan = require('morgan');
app.use(cors());
app.use(morgan('dev'));
app.use('/api', apiRoutes);

app.get('/', (req, res) => {
  res.send('Bem-vindo Ã  API do TalentMatchIA!');
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});

