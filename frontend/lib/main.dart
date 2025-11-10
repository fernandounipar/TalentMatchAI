import 'package:flutter/material.dart';
import 'telas/landing_tela.dart';
import 'telas/login_tela.dart';
import 'telas/registro_tela.dart';
import 'telas/dashboard_tela.dart';
import 'telas/vagas_tela.dart';
import 'telas/candidatos_tela.dart';
import 'telas/upload_curriculo_tela.dart';
import 'telas/analise_curriculo_tela.dart';
import 'telas/entrevista_assistida_tela.dart';
import 'telas/entrevistas_tela.dart';
import 'telas/relatorio_final_tela.dart';
import 'telas/relatorios_tela.dart';
import 'telas/usuarios_admin_tela.dart';
import 'telas/historico_tela.dart';
import 'telas/configuracoes_nova_tela.dart'; // Importa nova tela de configurações
import 'servicos/api_cliente.dart';
import 'design_system/tm_theme.dart';
import 'componentes/tm_app_shell.dart';

void main() => runApp(const TalentMatchIA());

// Enum das rotas seguindo o padrão React
enum RouteKey {
  landing,
  login,
  register,
  dashboard,
  vagas,
  novaVaga,
  candidatos,
  upload,
  analise,
  entrevistas,
  entrevista,
  relatorios,
  relatorio,
  historico,
  config,
  usuarios,
}

/// TalentMatchIA – Fluxo Completo
/// Simula o protótipo navegável de ponta a ponta:
/// 1) Landing/Home (marketing) → 2) Login → 3) Dashboard pós-login
/// 4) Vagas (lista + nova vaga) → 5) Candidatos (lista) → 6) Upload de Currículo
/// 7) Analisador de Currículo (IA) → 8) Entrevista Assistida (chat) → 9) Relatório Final
/// 10) Histórico → 11) Configurações
class TalentMatchIA extends StatefulWidget {
  const TalentMatchIA({super.key});

  @override
  State<TalentMatchIA> createState() => _TalentMatchIAState();
}

class _TalentMatchIAState extends State<TalentMatchIA> {
  static const String apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000');
  RouteKey route = RouteKey.landing;
  Map<String, dynamic> auth = {'logged': false, 'name': null};
  Map<String, dynamic>? userData; // Dados completos do usuário (incluindo empresa)
  Map<String, String> vagaForm = {
    'titulo': '',
    'descricao': '',
    'requisitos': '',
    'tecnologias': '',
  };
  String curriculoNome = '';
  Map<String, String> ctx = {
    'vagaSelecionada': 'Desenvolvedor Full Stack',
    'candidato': 'João Silva',
  };
  String? entrevistaId;
  Map<String, dynamic>? ultimoUpload;
  String? perfil;
  Map<String, dynamic>? relatorioFinal;

  // ApiCliente simples para satisfazer os requisitos das telas
  late final ApiCliente api;

  @override
  void initState() {
    super.initState();
    api = ApiCliente(baseUrl: apiBase);
  }

  /// Busca dados do usuário logado (com ou sem empresa)
  Future<void> _carregarDadosUsuario() async {
    try {
      final dados = await api.obterUsuario();
      setState(() {
        userData = dados;
        auth['name'] = dados['user']?['full_name'] ?? 'Usuário';
        perfil = dados['user']?['role'];
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados do usuário: $e');
    }
  }

  /// Realiza logout e limpa o estado
  void _logout() {
    setState(() {
      auth = {'logged': false, 'name': null};
      userData = null;
      perfil = null;
      route = RouteKey.landing;
      api.token = null;
      api.refreshToken = null;
    });
  }

  /// Formata o role do usuário para exibição
  String _formatarRole(String? role) {
    if (role == null) return 'usuário';
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      case 'USER':
      default:
        return 'Recrutador';
    }
  }

  void go(RouteKey to) {
    setState(() {
      route = to;
    });
  }

  String _sectionFromRoute(RouteKey r) {
    switch (r) {
      case RouteKey.dashboard:
        return 'dashboard';
      case RouteKey.vagas:
        return 'vagas';
      case RouteKey.candidatos:
        return 'candidatos';
      case RouteKey.upload:
        return 'upload';
      case RouteKey.entrevistas:
        return 'entrevistas';
      case RouteKey.historico:
        return 'historico';
      case RouteKey.config:
        return 'configuracoes';
      case RouteKey.usuarios:
        return 'configuracoes';
      case RouteKey.entrevista:
        return 'entrevistas';
      case RouteKey.relatorios:
        return 'relatorios';
      case RouteKey.relatorio:
        return 'relatorios';
      case RouteKey.novaVaga:
        return 'vagas';
      case RouteKey.landing:
      case RouteKey.login:
      case RouteKey.register:
      case RouteKey.analise:
        return 'dashboard';
    }
  }

  RouteKey _routeFromSection(String s) {
    switch (s) {
      case 'dashboard':
        return RouteKey.dashboard;
      case 'vagas':
        return RouteKey.vagas;
      case 'candidatos':
        return RouteKey.candidatos;
      case 'upload':
        return RouteKey.upload;
      case 'entrevistas':
        return RouteKey.entrevistas;
      case 'relatorios':
        return RouteKey.relatorios;
      case 'historico':
        return RouteKey.historico;
      case 'configuracoes':
        return RouteKey.config;
      default:
        return RouteKey.dashboard;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalentMatchIA',
      theme: TMTheme.light(),
      darkTheme: TMTheme.dark(),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: auth['logged'] == true
          ? TMAppShell(
              activeSection: _sectionFromRoute(route),
              onSectionChange: (s) => go(_routeFromSection(s)),
              userName: userData?['user']?['full_name'] ?? auth['name'] ?? 'Usuário',
              userRole: _formatarRole(userData?['user']?['role']),
              onLogout: _logout,
              child: _buildContent(),
            )
          : () {
              if (route == RouteKey.landing) {
                return LandingTela(
                  onLogin: () => go(RouteKey.login),
                  onDemo: () => go(RouteKey.login),
                );
              }
              if (route == RouteKey.register) {
                return RegistroTela(
                  api: api,
                  onCancel: () => go(RouteKey.login),
                  onSuccess: (resp) async {
                    setState(() {
                      auth = {
                        'logged': true,
                        'name': resp['usuario']?['nome'] ?? resp['user']?['full_name'] ?? 'Usuário',
                      };
                      perfil = resp['usuario']?['perfil'];
                      route = RouteKey.dashboard;
                    });
                    // Carrega dados completos do usuário após registro
                    await _carregarDadosUsuario();
                  },
                );
              }
              return LoginTela(
                onVoltar: () => go(RouteKey.landing),
                onSolicitarAcesso: () => go(RouteKey.register),
                onSubmit: (email, senha) async {
                  try {
                    final r = await api.entrar(email: email, senha: senha);
                    setState(() {
                      auth = {
                        'logged': true,
                        'name': r['usuario']?['nome'] ?? email.split('@')[0],
                      };
                      perfil = r['usuario']?['perfil'];
                      route = RouteKey.dashboard;
                    });
                    // Carrega dados completos do usuário após login
                    await _carregarDadosUsuario();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Falha no login')),
                    );
                  }
                },
              );
            }(),
    );
  }

  Widget _buildContent() {
    switch (route) {
      case RouteKey.dashboard:
        return DashboardTela(api: api);
      case RouteKey.register:
        return RegistroTela(
          api: api,
          onCancel: () => go(RouteKey.login),
          onSuccess: (resp) {
            setState(() {
              auth = {'logged': true, 'name': resp['usuario']?['nome'] ?? ''};
              perfil = resp['usuario']?['perfil'];
              route = RouteKey.dashboard;
            });
          },
        );
      case RouteKey.vagas:
        return VagasTela(api: api);
      case RouteKey.novaVaga:
        return _buildNovaVagaTela();
      case RouteKey.candidatos:
        return CandidatosTela(api: api);
      case RouteKey.upload:
        return UploadCurriculoTela(
          api: api,
          onUploaded: (resultado) {
            final cand = resultado['candidato'] ?? {};
            final cur = resultado['curriculo'] ?? {};
            final ent = resultado['entrevista'];
            final vaga = resultado['vaga'];
            setState(() {
              curriculoNome = cur['nome_arquivo'] ?? 'curriculo.pdf';
              ctx['candidato'] = cand['nome'] ?? ctx['candidato']!;
              if (vaga is Map) {
                ctx['vagaSelecionada'] = vaga['titulo']?.toString() ?? ctx['vagaSelecionada']!;
              }
              entrevistaId = ent != null ? ent['id'] : null;
              ultimoUpload = resultado;
              route = RouteKey.analise;
            });
          },
          onBack: () => go(RouteKey.dashboard),
        );
      case RouteKey.relatorios:
        return RelatoriosTela(
          api: api,
          onAbrirRelatorio: (candidato, vaga) {
            setState(() {
              ctx['candidato'] = candidato;
              ctx['vagaSelecionada'] = vaga;
              relatorioFinal = null;
              route = RouteKey.relatorio;
            });
          },
        );
      case RouteKey.entrevistas:
        return EntrevistasTela(
          api: api,
          onAbrirAssistida: (candidato, vaga) {
            setState(() {
              ctx['candidato'] = candidato;
              ctx['vagaSelecionada'] = vaga;
              entrevistaId = entrevistaId ?? 'ent-1';
              route = RouteKey.entrevista;
            });
          },
          onAbrirRelatorio: (candidato, vaga) {
            setState(() {
              ctx['candidato'] = candidato;
              ctx['vagaSelecionada'] = vaga;
              relatorioFinal = null;
              route = RouteKey.relatorio;
            });
          },
        );
      case RouteKey.analise:
        return AnaliseCurriculoTela(
          vaga: ctx['vagaSelecionada']!,
          candidato: ctx['candidato']!,
          arquivo: curriculoNome.isEmpty ? 'curriculo_joao_silva.pdf' : curriculoNome,
          fileUrl: (ultimoUpload != null) ? (ultimoUpload!['file']?['url'] as String?) : null,
          analise: (ultimoUpload != null) ? (ultimoUpload!['curriculo']?['analise_json'] as Map<String, dynamic>?) : null,
          onVoltar: () => go(RouteKey.upload),
          onEntrevistar: () => go(RouteKey.entrevista),
        );
      case RouteKey.entrevista:
        return EntrevistaAssistidaTela(
          candidato: ctx['candidato']!,
          vaga: ctx['vagaSelecionada']!,
          entrevistaId: entrevistaId ?? '',
          api: api,
          onFinalizar: (relatorio) {
            setState(() {
              relatorioFinal = relatorio;
              route = RouteKey.relatorio;
            });
          },
          onCancelar: () => go(RouteKey.dashboard),
        );
      case RouteKey.relatorio:
        return RelatorioFinalTela(
          candidato: ctx['candidato']!,
          vaga: ctx['vagaSelecionada']!,
          relatorio: relatorioFinal,
          onVoltar: () => go(RouteKey.dashboard),
        );
      case RouteKey.historico:
        return HistoricoTela(api: api);
      case RouteKey.config:
        return ConfiguracoesNovaTela(api: api);
      case RouteKey.usuarios:
        return UsuariosAdminTela(api: api, isAdmin: (perfil == 'ADMIN'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNovaVagaTela() {
    final controllers = {
      'titulo': TextEditingController(text: vagaForm['titulo']),
      'descricao': TextEditingController(text: vagaForm['descricao']),
      'requisitos': TextEditingController(text: vagaForm['requisitos']),
      'tecnologias': TextEditingController(text: vagaForm['tecnologias']),
    };

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => go(RouteKey.vagas),
                icon: const Icon(Icons.chevron_left, size: 16),
                label: const Text('Voltar'),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nova Vaga',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Título',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controllers['titulo'],
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Desenvolvedor Full Stack',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => vagaForm['titulo'] = value,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descrição',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controllers['descricao'],
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Resumo da vaga',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => vagaForm['descricao'] = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requisitos',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: controllers['requisitos'],
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Habilidades, experiências',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => vagaForm['requisitos'] = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tecnologias',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: controllers['tecnologias'],
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  hintText: 'Ex.: React, Node.js, SQL',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => vagaForm['tecnologias'] = value,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => go(RouteKey.vagas),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Salvar vaga e voltar
                            go(RouteKey.vagas);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Salvar Vaga'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- Layout Logado -------------------- */
class AppShell extends StatelessWidget {
  final Widget child;
  final Function(RouteKey) onNavigate;
  final RouteKey route;
  final String name;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.child,
    required this.onNavigate,
    required this.route,
    required this.name,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': RouteKey.dashboard, 'label': 'Dashboard', 'icon': Icons.home},
      {'key': RouteKey.vagas, 'label': 'Vagas', 'icon': Icons.work},
      {'key': RouteKey.candidatos, 'label': 'Candidatos', 'icon': Icons.people},
      {'key': RouteKey.upload, 'label': 'Upload', 'icon': Icons.upload},
      {'key': RouteKey.historico, 'label': 'Histórico', 'icon': Icons.assignment},
      {'key': RouteKey.config, 'label': 'Configurações', 'icon': Icons.settings},
      {'key': RouteKey.usuarios, 'label': 'Usuários', 'icon': Icons.admin_panel_settings},
    ];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          LayoutBuilder(
            builder: (context, constraints) {
              if (MediaQuery.of(context).size.width < 768) {
                return const SizedBox.shrink();
              }
              return Container(
                width: 256,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo header
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TalentMatchIA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4338CA),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    // Navigation
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: items.map((item) {
                            final isSelected = route == item['key'];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: InkWell(
                                onTap: () => onNavigate(item['key'] as RouteKey),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF4F46E5),
                                              Color(0xFF6366F1),
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item['icon'] as IconData,
                                        size: 20,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        item['label'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 256),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar candidato, vaga ou relatório',
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // User info and logout
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Recrutadora',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFFD946EF),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: onLogout,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Sair',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
