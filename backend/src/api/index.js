const express = require('express');
const router = express.Router();

// Importar rotas
const rotasUsuarios = require('./rotas/usuarios');
const rotasVagas = require('./rotas/vagas');
const rotasAutenticacao = require('./rotas/autenticacao');
const rotasCurriculos = require('./rotas/curriculos');
const rotasEntrevistas = require('./rotas/entrevistas');
const rotasDashboard = require('./rotas/dashboard');
const rotasCandidatos = require('./rotas/candidatos');
const rotasHistorico = require('./rotas/historico');
const rotasCompanies = require('./rotas/companies');

// Montar rotas
router.use('/usuarios', rotasUsuarios);
router.use('/vagas', rotasVagas);
router.use('/auth', rotasAutenticacao);
router.use('/curriculos', rotasCurriculos);
router.use('/entrevistas', rotasEntrevistas);
router.use('/dashboard', rotasDashboard);
router.use('/candidatos', rotasCandidatos);
router.use('/historico', rotasHistorico);
router.use('/companies', rotasCompanies);

module.exports = router;
