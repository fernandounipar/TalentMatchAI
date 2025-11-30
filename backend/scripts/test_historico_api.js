const http = require('http');

// Login
const loginData = JSON.stringify({
  email: 'fernando@email.com',
  senha: 'admin123'
});

const loginReq = http.request({
  hostname: 'localhost',
  port: 4000,
  path: '/api/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': loginData.length
  }
}, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log('Resposta login:', body.substring(0, 100) + '...');
    const parsed = JSON.parse(body);
    const token = parsed.access_token || parsed.token;
    if (!token) {
      console.error('Token não encontrado na resposta');
      process.exit(1);
    }
    console.log('Token obtido:', token.substring(0, 50) + '...');
    
    // Buscar histórico
    const histReq = http.request({
      hostname: 'localhost',
      port: 4000,
      path: '/api/historico',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    }, (res2) => {
      let body2 = '';
      res2.on('data', chunk => body2 += chunk);
      res2.on('end', () => {
        const hist = JSON.parse(body2);
        console.log('\n=== HISTÓRICO ===');
        console.log('Total de itens:', hist.length);
        
        const comRelatorio = hist.filter(e => e.tem_relatorio === true);
        console.log('Com relatório:', comRelatorio.length);
        
        for (const item of comRelatorio) {
          console.log(`\n  ID: ${item.id}`);
          console.log(`  Candidato: ${item.candidato}`);
          console.log(`  Vaga: ${item.vaga}`);
          console.log(`  tem_relatorio: ${item.tem_relatorio}`);
          console.log(`  relatorio_recomendacao: ${item.relatorio_recomendacao}`);
          console.log(`  overall_score: ${item.overall_score}`);
          console.log(`  tipo overall_score: ${typeof item.overall_score}`);
          
          // Buscar relatório individual
          const reportReq = http.request({
            hostname: 'localhost',
            port: 4000,
            path: `/api/interviews/${item.id}/report`,
            method: 'GET',
            headers: {
              'Authorization': `Bearer ${token}`
            }
          }, (res3) => {
            let body3 = '';
            res3.on('data', chunk => body3 += chunk);
            res3.on('end', () => {
              console.log('\n  === RELATÓRIO ===');
              const report = JSON.parse(body3);
              console.log('  Status HTTP:', res3.statusCode);
              if (report.data) {
                console.log('  overall_score:', report.data.overall_score);
                console.log('  tipo overall_score:', typeof report.data.overall_score);
                console.log('  recommendation:', report.data.recommendation);
                console.log('  candidate_name:', report.data.candidate_name);
              } else if (report.erro) {
                console.log('  ERRO:', report.erro);
              }
              process.exit(0);
            });
          });
          reportReq.on('error', e => { console.error('Erro report:', e); });
          reportReq.end();
          return; // Só pegar o primeiro
        }
        
        process.exit(0);
      });
    });
    histReq.on('error', e => { console.error('Erro hist:', e); process.exit(1); });
    histReq.end();
  });
});

loginReq.on('error', e => { console.error('Erro login:', e); process.exit(1); });
loginReq.write(loginData);
loginReq.end();
