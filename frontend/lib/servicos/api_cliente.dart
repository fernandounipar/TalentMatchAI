import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'mock_database.dart';

class ApiCliente {
  final String baseUrl;
  String? _token;
  final bool usarMock;
  final MockDatabase mock;

  ApiCliente({
    required this.baseUrl,
    this.usarMock = true,
    MockDatabase? mock,
  }) : mock = mock ?? MockDatabase();

  Map<String, String> _headers({Map<String, String>? extra}) => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  set token(String? t) => _token = t;

  Future<T> _withMock<T>(Future<T> Function() call, T Function() fallback) async {
    if (!usarMock) {
      try {
        return await call();
      } catch (_) {
        // Em caso de falha na API real, caímos no mock
      }
    }
    return fallback();
  }

  Future<Map<String, dynamic>> entrar({required String email, required String senha}) async {
    return _withMock(() async {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'senha': senha}),
      );
      if (resp.statusCode >= 400) throw Exception(resp.body);
      final data = jsonDecode(resp.body);
      token = data['token'];
      return data;
    }, () {
      final data = mock.login(email, senha);
      token = data['token'];
      return data;
    });
  }

  Future<Map<String, dynamic>> dashboard() async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/dashboard'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.dashboard());
  }

  Future<List<dynamic>> vagas() async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/vagas'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.vagas());
  }

  Future<Map<String, dynamic>> criarVaga(Map<String, dynamic> vaga) async {
    return _withMock(() async {
      final r = await http.post(Uri.parse('$baseUrl/api/vagas'), headers: _headers(), body: jsonEncode(vaga));
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.criarVaga(vaga));
  }

  Future<List<dynamic>> candidatos() async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/candidatos'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.candidatos());
  }

  Future<List<dynamic>> historico() async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/historico'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.historico());
  }

  Future<Map<String, dynamic>> entrevista(String id) async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/entrevistas/$id'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => {'id': id});
  }

  Future<List<dynamic>> gerarPerguntas(String entrevistaId, {int qtd = 8}) async {
    return _withMock(() async {
      final r = await http.post(Uri.parse('$baseUrl/api/entrevistas/$entrevistaId/perguntas?qtd=$qtd'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.gerarPerguntas(entrevistaId, qtd: qtd));
  }

  // Upload de currículo (multipart/form-data) usando bytes
  Future<Map<String, dynamic>> uploadCurriculoBytes({
    required Uint8List bytes,
    required String filename,
    Map<String, dynamic>? candidato,
    String? vagaId,
  }) async {
    return _withMock(() async {
      final uri = Uri.parse('$baseUrl/api/curriculos/upload');
      final req = http.MultipartRequest('POST', uri);
      if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
      req.files.add(http.MultipartFile.fromBytes('arquivo', bytes, filename: filename));
      if (candidato != null) req.fields['candidato'] = jsonEncode(candidato);
      if (vagaId != null) req.fields['vagaId'] = vagaId;
      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 400) throw Exception(resp.body);
      return jsonDecode(resp.body);
    }, () => mock.uploadCurriculo(filename: filename, candidato: candidato, vagaId: vagaId));
  }

  // Chat - listar mensagens
  Future<List<dynamic>> listarMensagens(String entrevistaId) async {
    return _withMock(() async {
      final r = await http.get(Uri.parse('$baseUrl/api/entrevistas/$entrevistaId/mensagens'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.listarMensagens(entrevistaId));
  }

  // Chat - enviar mensagem
  Future<Map<String, dynamic>> enviarMensagem(String entrevistaId, String mensagem) async {
    return _withMock(() async {
      final r = await http.post(
        Uri.parse('$baseUrl/api/entrevistas/$entrevistaId/chat'),
        headers: _headers(),
        body: jsonEncode({'mensagem': mensagem}),
      );
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.enviarMensagem(entrevistaId, mensagem));
  }

  // Relatório - gerar/atualizar
  Future<Map<String, dynamic>> gerarRelatorio(String entrevistaId) async {
    return _withMock(() async {
      final r = await http.post(Uri.parse('$baseUrl/api/entrevistas/$entrevistaId/relatorio'), headers: _headers());
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.gerarRelatorio(entrevistaId));
  }

  // Usuários - criar (admin only)
  Future<Map<String, dynamic>> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    String perfil = 'RECRUTADOR',
    Map<String, dynamic>? company,
  }) async {
    return _withMock(() async {
      final r = await http.post(
        Uri.parse('$baseUrl/api/usuarios'),
        headers: _headers(),
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'senha': senha,
          'perfil': perfil,
          if (company != null) 'company': company
        }),
      );
      if (r.statusCode >= 400) throw Exception(r.body);
      return jsonDecode(r.body);
    }, () => mock.criarUsuario(nome: nome, email: email, senha: senha, perfil: perfil, company: company));
  }
}
