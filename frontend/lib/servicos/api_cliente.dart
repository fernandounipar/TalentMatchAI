import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiCliente {
  final String baseUrl;
  String? _token;

  ApiCliente({required this.baseUrl});

  Map<String, String> _headers({Map<String, String>? extra}) => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  set token(String? t) => _token = t;

  Future<Map<String, dynamic>> entrar({required String email, required String senha}) async {
    final resp = await http.post(Uri.parse('$baseUrl/api/auth/login'), headers: _headers(), body: jsonEncode({ 'email': email, 'senha': senha }));
    if (resp.statusCode >= 400) throw Exception(resp.body);
    final data = jsonDecode(resp.body);
    token = data['token'];
    return data;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final r = await http.get(Uri.parse('$baseUrl/api/dashboard'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<List<dynamic>> vagas() async {
    final r = await http.get(Uri.parse('$baseUrl/api/vagas'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> criarVaga(Map<String, dynamic> vaga) async {
    final r = await http.post(Uri.parse('$baseUrl/api/vagas'), headers: _headers(), body: jsonEncode(vaga));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<List<dynamic>> candidatos() async {
    final r = await http.get(Uri.parse('$baseUrl/api/candidatos'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
    }

  Future<List<dynamic>> historico() async {
    final r = await http.get(Uri.parse('$baseUrl/api/historico'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> entrevista(String id) async {
    final r = await http.get(Uri.parse('$baseUrl/api/entrevistas/$id'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<List<dynamic>> gerarPerguntas(String entrevistaId, {int qtd = 8}) async {
    final r = await http.post(Uri.parse('$baseUrl/api/entrevistas/$entrevistaId/perguntas?qtd=$qtd'), headers: _headers());
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }
}


