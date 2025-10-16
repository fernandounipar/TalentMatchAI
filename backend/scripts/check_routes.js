try {
  require('../src/api/rotas/entrevistas');
  require('../src/api/rotas/curriculos');
  require('../src/api/rotas/autenticacao');
  console.log('Rotas carregadas com sucesso.');
} catch (e) {
  console.error('Falha ao carregar rotas:', e);
  process.exit(1);
}

