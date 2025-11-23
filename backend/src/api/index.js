const express = require('express');
const router = express.Router();

// Importar rotas
const rotasUsuarios = require('./rotas/usuarios');
const rotasAutenticacao = require('./rotas/autenticacao');
const rotasUser = require('./rotas/user');
const rotasDashboard = require('./rotas/dashboard');
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
// RF3 e RF7 - Reativadas após integração completa
const rotasReports = require('./rotas/reports');
const rotasGithub = require('./rotas/github');

// Montar rotas
router.use('/usuarios', rotasUsuarios);
router.use('/auth', rotasAutenticacao);
router.use('/user', rotasUser);
router.use('/dashboard', rotasDashboard);
router.use('/historico', rotasHistorico);
router.use('/companies', rotasCompanies);
router.use('/jobs', rotasJobs);
router.use('/vagas', rotasJobs); // alias em pt-BR para o frontend
router.use('/candidates', rotasCandidates);
router.use('/skills', rotasSkills);
router.use('/', rotasPipelines); // /jobs/:jobId/pipeline
router.use('/applications', rotasApplications);
router.use('/interviews', rotasInterviews);
router.use('/files', rotasFiles);
router.use('/ingestion', rotasIngestion);
router.use('/resumes', rotasResumes);
router.use('/curriculos', rotasResumes); // alias pt-BR para upload/listagem
router.use('/api-keys', rotasApiKeys);
router.use('/reports', rotasReports); // RF7 - Relatórios detalhados
router.use('/candidates', rotasGithub); // GitHub routes: /api/candidates/:id/github

module.exports = router;
