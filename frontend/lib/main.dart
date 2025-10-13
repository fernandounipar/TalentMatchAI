import 'package:flutter/material.dart';
import 'telas/landing_tela.dart';
import 'telas/login_tela.dart';
import 'telas/dashboard_tela.dart';
import 'telas/vagas_tela.dart';
import 'telas/candidatos_tela.dart';
import 'telas/upload_curriculo_tela.dart';
import 'telas/analise_curriculo_tela.dart';
import 'telas/entrevista_assistida_tela.dart';
import 'telas/relatorio_final_tela.dart';
import 'telas/historico_tela.dart';
import 'telas/configuracoes_tela.dart';
import 'componentes/widgets.dart';

void main() => runApp(const TalentMatchIA());

// Enum das rotas seguindo o padrão React
enum RouteKey {
  landing,
  login,
  dashboard,
  vagas,
  novaVaga,
  candidatos,
  upload,
  analise,
  entrevista,
  relatorio,
  historico,
  config,
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
  RouteKey route = RouteKey.landing;
  Map<String, dynamic> auth = {'logged': false, 'name': null};
  Map<String, String> vagaForm = {
    'titulo': '',
    'descricao': '',
    'requisitos': '',
    'tecnologias': ''
  };
  String curriculoNome = '';
  Map<String, String> ctx = {
    'vagaSelecionada': 'Desenvolvedor Full Stack',
    'candidato': 'João Silva'
  };

  void go(RouteKey to) {
    setState(() {
      route = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalentMatchIA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F3FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: auth['logged'] == true
            ? AppShell(
                onNavigate: go,
                route: route,
                name: auth['name'] ?? 'Recrutadora',
                child: _buildContent(),
              )
            : route == RouteKey.landing
                ? LandingTela(
                    onLogin: () => go(RouteKey.login),
                    onDemo: () => go(RouteKey.login),
                  )
                : LoginTela(
                    onVoltar: () => go(RouteKey.landing),
                    onSubmit: (email) {
                      setState(() {
                        auth = {
                          'logged': true,
                          'name': email.split('@')[0],
                        };
                        route = RouteKey.dashboard;
                      });
                    },
                  ),
      ),
    );
  }

  Widget _buildContent() {
    switch (route) {
      case RouteKey.dashboard:
        return Dashboard(onNavigate: go);
      case RouteKey.vagas:
        return Vagas(
          onNavigate: go,
          onNovaVaga: () => go(RouteKey.novaVaga),
        );
      case RouteKey.novaVaga:
        return NovaVaga(
          form: vagaForm,
          onChange: (newForm) => setState(() => vagaForm = newForm),
          onCancel: () => go(RouteKey.vagas),
          onSave: () => go(RouteKey.vagas),
        );
      case RouteKey.candidatos:
        return Candidatos(onNavigate: go);
      case RouteKey.upload:
        return UploadCurriculo(
          curriculoNome: curriculoNome,
          onFile: (name) {
            setState(() {
              curriculoNome = name;
            });
            go(RouteKey.analise);
          },
          onBack: () => go(RouteKey.dashboard),
        );
      case RouteKey.analise:
        return AnaliseCurriculo(
          vaga: ctx['vagaSelecionada']!,
          candidato: ctx['candidato']!,
          arquivo: curriculoNome.isEmpty ? 'curriculo_joao_silva.pdf' : curriculoNome,
          onEntrevistar: () => go(RouteKey.entrevista),
          onVoltar: () => go(RouteKey.upload),
        );
      case RouteKey.entrevista:
        return EntrevistaAssistida(
          candidato: ctx['candidato']!,
          vaga: ctx['vagaSelecionada']!,
          onFinalizar: () => go(RouteKey.relatorio),
          onCancelar: () => go(RouteKey.dashboard),
        );
      case RouteKey.relatorio:
        return RelatorioFinal(
          candidato: ctx['candidato']!,
          vaga: ctx['vagaSelecionada']!,
          onVoltar: () => go(RouteKey.dashboard),
        );
      case RouteKey.historico:
        return Historico(onNavigate: go);
      case RouteKey.config:
        return const Configuracoes();
      default:
        return const SizedBox.shrink();
    }
  }
}

/* -------------------- Layout Logado -------------------- */
class AppShell extends StatelessWidget {
  final Widget child;
  final Function(RouteKey) onNavigate;
  final RouteKey route;
  final String name;

  const AppShell({
    super.key,
    required this.child,
    required this.onNavigate,
    required this.route,
    required this.name,
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
                              onPressed: () {
                                // Implementar logout
                              },
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child; final RouteKey route; final String name; final VoidCallback onLogout; final void Function(RouteKey) onNavigate;
  const AppShell({super.key, required this.child, required this.route, required this.name, required this.onLogout, required this.onNavigate});
  @override
  Widget build(BuildContext context) {
    final items = const [
      (RouteKey.dashboard, Icons.home_outlined, 'Dashboard'),
      (RouteKey.vagas, Icons.work_outline, 'Vagas'),
      (RouteKey.candidatos, Icons.people_outline, 'Candidatos'),
      (RouteKey.upload, Icons.upload_outlined, 'Upload'),
      (RouteKey.historico, Icons.receipt_long_outlined, 'HistÃ³rico'),
      (RouteKey.config, Icons.settings_outlined, 'ConfiguraÃ§Ãµes'),
    ];
    return Row(children: [
      LayoutBuilder(builder: (_, c){
        final wide = c.maxWidth > 900; if(!wide) return const SizedBox.shrink();
        return Container(width: 230, color: Colors.white, child: Column(children: [
          Container(height: 64, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))), child: const Text('TalentMatchIA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF4338CA)))),
          Expanded(child: ListView(padding: const EdgeInsets.all(8), children: [
            for (final it in items)
              _SideButton(selected: route==it.$1, icon: it.$2, label: it.$3, onTap: () => onNavigate(it.$1)),
          ])),
        ]));
      }),
      Expanded(child: Column(children: [
        Container(height: 64, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 18), hintText: 'Buscar candidato, vaga ou relatÃ³rio', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))))),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600)), const Text('Recrutadora', style: TextStyle(fontSize: 11, color: Colors.grey))]),
            const SizedBox(width: 8), const CircleAvatar(radius: 16, backgroundColor: Colors.indigo), const SizedBox(width: 8),
            OutlinedButton(onPressed: onLogout, child: const Text('Sair')),
          ]),
        ])),
        Expanded(child: SingleChildScrollView(child: child)),
      ])),
    ]);
  }
}

class _SideButton extends StatelessWidget {
  final bool selected; final IconData icon; final String label; final VoidCallback onTap;
  const _SideButton({required this.selected, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: Container(
      height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: selected ? const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF6366F1)]) : null),
      child: Row(children: [Icon(icon, size: 20, color: selected?Colors.white:Colors.black87), const SizedBox(width: 8), Text(label, style: TextStyle(color: selected?Colors.white:Colors.black87, fontWeight: FontWeight.w500))]),
    )),
  );
}

// Landing movida para telas/landing_tela.dart
// Login
class LoginTela extends StatefulWidget { final VoidCallback onBack; final void Function(String) onSubmit; const LoginTela({super.key, required this.onBack, required this.onSubmit});
  @override State<LoginTela> createState() => _LoginTelaState(); }
class _LoginTelaState extends State<LoginTela> { final _email=TextEditingController(); final _pwd=TextEditingController();
  @override void dispose(){_email.dispose(); _pwd.dispose(); super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor: const Color(0xFFF5F7FF), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.chevron_left), label: const Text('Voltar'))),
    const SizedBox(height: 8), const Text('Acessar TalentMatchIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF3730A3))), const SizedBox(height: 10),
    const Text('E-mail', style: TextStyle(fontSize: 12)), TextField(controller: _email, decoration: const InputDecoration(hintText: 'seu@email.com')),
    const SizedBox(height: 10), const Text('Senha', style: TextStyle(fontSize: 12)), TextField(controller: _pwd, obscureText: true, decoration: const InputDecoration(hintText: 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢')),
    const SizedBox(height: 14), ElevatedButton.icon(onPressed: ()=>widget.onSubmit(_email.text.trim()), icon: const Icon(Icons.login), label: const Text('Entrar'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white)),
  ]))))));
}

// Nova Vaga (simplificada)
class NovaVagaTela extends StatefulWidget { final VoidCallback onCancel; final VoidCallback onSave; const NovaVagaTela({super.key, required this.onCancel, required this.onSave});
  @override State<NovaVagaTela> createState()=>_NovaVagaTelaState(); }
class _NovaVagaTelaState extends State<NovaVagaTela>{ final t=TextEditingController(), d=TextEditingController(), r=TextEditingController(), tec=TextEditingController();
  @override void dispose(){t.dispose(); d.dispose(); r.dispose(); tec.dispose(); super.dispose();}
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    TextButton.icon(onPressed: widget.onCancel, icon: const Icon(Icons.chevron_left), label: const Text('Voltar')),
    const Text('Nova Vaga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8),
    Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
      TextField(controller:t, decoration: const InputDecoration(labelText:'TÃ­tulo')), const SizedBox(height:8),
      TextField(controller:d, decoration: const InputDecoration(labelText:'DescriÃ§Ã£o'), maxLines:3), const SizedBox(height:8),
      Row(children:[Expanded(child: TextField(controller:r, decoration: const InputDecoration(labelText:'Requisitos'), maxLines:3)), const SizedBox(width:8), Expanded(child: TextField(controller:tec, decoration: const InputDecoration(labelText:'Tecnologias'), maxLines:3))]), const SizedBox(height:8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children:[OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancelar')), const SizedBox(width:8), ElevatedButton(onPressed: widget.onSave, child: const Text('Salvar Vaga'))])
    ]))),
  ]);
}

