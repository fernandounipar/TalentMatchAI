const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const authService = require('../../servicos/autenticacaoService');
const { exigirAutenticacao } = require('../../middlewares/autenticacao');

// Rate limiting para rotas de autenticação (proteção contra brute force)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 10, // máximo 10 requisições por janela por IP
  message: { erro: 'Muitas tentativas. Tente novamente em 15 minutos.' }
});

/**
 * POST /api/auth/register
 * Registra nova empresa + primeiro usuário
 * Body: { type: 'CPF'|'CNPJ', document, name, user: {full_name, email, password, role?} }
 */
router.post('/register', authLimiter, async (req, res) => {
  try {
    const resultado = await authService.registrar(req.body);
    res.status(201).json(resultado);
  } catch (error) {
    console.error('❌ Erro no registro:', error.message);
    res.status(400).json({ erro: error.message });
  }
});

/**
 * POST /api/auth/login
 * Login com email e senha
 * Body: { email, senha }
 */
router.post('/login', authLimiter, async (req, res) => {
  try {
    const { email, senha } = req.body;
    const resultado = await authService.login(email, senha);
    res.json(resultado);
  } catch (error) {
    console.error('❌ Erro no login:', error.message);
    res.status(401).json({ erro: error.message });
  }
});

/**
 * POST /api/auth/refresh
 * Renova access token usando refresh token (com rotação)
 * Body: { refresh_token }
 */
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    const resultado = await authService.refresh(refresh_token);
    res.json(resultado);
  } catch (error) {
    console.error('❌ Erro no refresh:', error.message);
    res.status(401).json({ erro: error.message });
  }
});

/**
 * POST /api/auth/logout
 * Revoga refresh token
 * Body: { refresh_token }
 */
router.post('/logout', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    await authService.logout(refresh_token);
    res.json({ mensagem: 'Logout realizado com sucesso' });
  } catch (error) {
    console.error('❌ Erro no logout:', error.message);
    res.status(500).json({ erro: 'Erro ao fazer logout' });
  }
});

/**
 * POST /api/auth/forgot-password
 * Solicita reset de senha (gera token)
 * Body: { email }
 */
router.post('/forgot-password', authLimiter, async (req, res) => {
  try {
    const { email } = req.body;
    const resultado = await authService.solicitarResetSenha(email);
    
    if (resultado) {
      // Em produção, envie o reset_token por email
      // Para MVP/desenvolvimento, retornamos no response
      res.json({ 
        mensagem: 'Se o email existir, você receberá instruções para reset.',
        // REMOVER EM PRODUÇÃO:
        reset_token: resultado.reset_token 
      });
    } else {
      // Por segurança, sempre retorna sucesso mesmo se email não existe
      res.json({ mensagem: 'Se o email existir, você receberá instruções para reset.' });
    }
  } catch (error) {
    console.error('❌ Erro ao solicitar reset:', error.message);
    res.status(500).json({ erro: 'Erro ao processar solicitação' });
  }
});

/**
 * POST /api/auth/reset-password
 * Reset de senha com token
 * Body: { reset_token, nova_senha }
 */
router.post('/reset-password', async (req, res) => {
  try {
    const { reset_token, nova_senha } = req.body;
    await authService.resetSenha(reset_token, nova_senha);
    res.json({ mensagem: 'Senha redefinida com sucesso. Faça login novamente.' });
  } catch (error) {
    console.error('❌ Erro ao resetar senha:', error.message);
    res.status(400).json({ erro: error.message });
  }
});

/**
 * POST /api/auth/change-password
 * Trocar senha (usuário logado)
 * Body: { senha_atual, nova_senha }
 * Requer autenticação
 */
router.post('/change-password', exigirAutenticacao, async (req, res) => {
  try {
    const { senha_atual, nova_senha } = req.body;
    const user_id = req.usuario.id;
    
    await authService.trocarSenha(user_id, senha_atual, nova_senha);
    res.json({ mensagem: 'Senha alterada com sucesso. Faça login novamente.' });
  } catch (error) {
    console.error('❌ Erro ao trocar senha:', error.message);
    res.status(400).json({ erro: error.message });
  }
});

/**
 * GET /api/auth/me
 * Retorna dados do usuário autenticado
 * Requer autenticação
 */
router.get('/me', exigirAutenticacao, async (req, res) => {
  try {
    res.json({ usuario: req.usuario });
  } catch (error) {
    console.error('❌ Erro ao buscar usuário:', error.message);
    res.status(500).json({ erro: 'Erro ao buscar dados do usuário' });
  }
});

module.exports = router;

