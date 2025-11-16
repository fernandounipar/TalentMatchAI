/**
 * Lista todas as rotas registradas no Express
 */

const express = require('express');
const app = express();

// Importar o index de rotas
const apiRoutes = require('../src/api/index');

app.use('/api', apiRoutes);

function listRoutes(stack, prefix = '') {
  const routes = [];
  
  stack.forEach((middleware) => {
    if (middleware.route) {
      // Rota direta
      const methods = Object.keys(middleware.route.methods).join(', ').toUpperCase();
      routes.push(`${methods.padEnd(10)} ${prefix}${middleware.route.path}`);
    } else if (middleware.name === 'router' && middleware.handle.stack) {
      // Sub-router
      const newPrefix = middleware.regexp.source
        .replace('\\/?', '')
        .replace('(?=\\/|$)', '')
        .replace(/\\\//g, '/')
        .replace(/\^/g, '')
        .replace(/\$/g, '')
        .replace(/\(\?\:/, '')
        .replace(/\)/g, '');
      
      routes.push(...listRoutes(middleware.handle.stack, prefix + newPrefix));
    }
  });
  
  return routes;
}

console.log('📋 Rotas registradas no backend:\n');

const routes = listRoutes(app._router.stack);
const apiKeyRoutes = routes.filter(r => r.includes('api-keys'));

console.log('🔑 Rotas de API Keys:');
apiKeyRoutes.forEach(r => console.log('  ', r));

if (apiKeyRoutes.length === 0) {
  console.log('  ⚠️  Nenhuma rota de api-keys encontrada!');
}

console.log('\n📊 Total de rotas:', routes.length);
console.log('\n🔍 Buscando especificamente DELETE /api/api-keys/:id...');

const deleteRoute = routes.find(r => 
  r.includes('DELETE') && r.includes('api-keys') && r.includes(':id')
);

if (deleteRoute) {
  console.log('✅ Encontrada:', deleteRoute);
} else {
  console.log('❌ Rota DELETE não encontrada!');
  console.log('\n🔍 Todas as rotas de api-keys:');
  apiKeyRoutes.forEach(r => console.log('  ', r));
}
