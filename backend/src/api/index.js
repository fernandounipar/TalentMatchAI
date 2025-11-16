const express = require('express');
const router = express.Router();

// Importar rotas
const rotasUsuarios = require('./rotas/usuarios');
const rotasVagas = require('./rotas/vagas');
const rotasAutenticacao = require('./rotas/autenticacao');
const rotasUser = require('./rotas/user');
const rotasCurriculos = require('./rotas/curriculos');
const rotasEntrevistas = require('./rotas/entrevistas');
const rotasDashboard = require('./rotas/dashboard');
const rotasCandidatos = require('./rotas/candidatos');
const rotasHistorico = require('./rotas/historico');
const rotasCompanies = require('./rotas/companies');
const rotasJobs = require('./rotas/jobs');
const rotasCandidates = require('./rotas/candidates');
const rotasSkills = require('./rotas/skills');
const rotasApplications = require('./rotas/applications');
const rotasPipelines = require('./rotas/pipelines');
const rotasInterviews = require('./rotas/interviews');
const rotasFiles = require('./rotas/files');
const rotasIngestion = require('./rotas/ingestion');
const rotasResumes = require('./rotas/resumes');
const rotasApiKeys = require('./rotas/api_keys');

// Montar rotas
router.use('/usuarios', rotasUsuarios);
router.use('/vagas', rotasVagas);
router.use('/auth', rotasAutenticacao);
router.use('/user', rotasUser);
router.use('/curriculos', rotasCurriculos);
router.use('/entrevistas', rotasEntrevistas);
router.use('/dashboard', rotasDashboard);
router.use('/candidatos', rotasCandidatos);
router.use('/historico', rotasHistorico);
router.use('/companies', rotasCompanies);
router.use('/jobs', rotasJobs);
router.use('/candidates', rotasCandidates);
router.use('/skills', rotasSkills);
router.use('/', rotasPipelines); // /jobs/:jobId/pipeline
router.use('/applications', rotasApplications);
router.use('/interviews', rotasInterviews);
router.use('/files', rotasFiles);
router.use('/ingestion', rotasIngestion);
router.use('/resumes', rotasResumes);
router.use('/api-keys', rotasApiKeys);

module.exports = router;
