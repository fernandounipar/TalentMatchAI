import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiCliente {
  final String baseUrl;
  String? _token;
  String? _refresh;
  // mocks removidos

  ApiCliente({
    required this.baseUrl,
  });

  Map<String, String> _headers({Map<String, String>? extra}) => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  set token(String? t) => _token = t;
  set refreshToken(String? t) => _refresh = t;

  // Helper para extrair listas de respostas com envelope {data}
  List<dynamic> _asList(dynamic body) {
    if (body is List) return body;
    if (body is Map && body['data'] is List) return body['data'] as List;
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }

  Future<http.Response> _execWithRefresh(
      Future<http.Response> Function() call) async {
    final resp = await call();
    if (resp.statusCode == 401 && _refresh != null) {
      final ok = await _tryRefresh();
      if (ok) {
        return await call();
      }
    }
    return resp;
  }

  Future<bool> _tryRefresh() async {
    try {
      final r = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _headers(),
        body: jsonEncode({'refresh_token': _refresh}),
      );
      if (r.statusCode >= 400) return false;
      final data = jsonDecode(r.body);
      token = data['access_token'];
      refreshToken = data['refresh_token'] ?? _refresh;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Removido suporte a mocks: todas as chamadas utilizam API real

  Future<Map<String, dynamic>> entrar(
      {required String email, required String senha}) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    if (resp.statusCode >= 400) {
      throw Exception(resp.body);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    token = data['access_token'] ?? data['token'];
    refreshToken = data['refresh_token'];
    return data;
  }

  Future<Map<String, dynamic>> registrar({
    required String nomeCompleto,
    required String email,
    required String senha,
  }) async {
    final payload = {
      'full_name': nomeCompleto,
      'email': email,
      'password': senha,
    };
    final resp = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (resp.statusCode >= 400) {
      throw Exception(resp.body);
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    token = data['access_token'] ?? data['token'];
    refreshToken = data['refresh_token'];
    return data;
  }

  /// Busca dados do usuário logado (com ou sem empresa)
  Future<Map<String, dynamic>> obterUsuario() async {
    final r = await _execWithRefresh(
        () => http.get(Uri.parse('$baseUrl/api/user/me'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Cria ou atualiza empresa do usuário logado
  Future<Map<String, dynamic>> criarOuAtualizarEmpresa({
    required String tipo, // 'CPF' ou 'CNPJ'
    required String documento,
    required String nome,
  }) async {
    final payload = {
      'type': tipo,
      'document': documento,
      'name': nome,
    };
    final r = await _execWithRefresh(
      () => http.post(
        Uri.parse('$baseUrl/api/user/company'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    if (r.statusCode >= 400) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {
        // fallback para corpo bruto
      }
      throw Exception(r.body);
    }
    final result = jsonDecode(r.body) as Map<String, dynamic>;

    // Se o backend retornou um novo token (após criar empresa), atualiza
    if (result['access_token'] != null) {
      _token = result['access_token'] as String;
    }

    return result;
  }

  /// Atualiza perfil do usuário (nome, cargo)
  Future<Map<String, dynamic>> atualizarPerfil({
    String? fullName,
    String? cargo,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (cargo != null) payload['cargo'] = cargo;

    final r = await _execWithRefresh(
      () => http.put(
        Uri.parse('$baseUrl/api/user/profile'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    if (r.statusCode >= 400) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {}
      throw Exception(r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Atualiza foto/avatar do usuário
  Future<Map<String, dynamic>> atualizarAvatar(String fotoUrl) async {
    final payload = {'foto_url': fotoUrl};
    final r = await _execWithRefresh(
      () => http.post(
        Uri.parse('$baseUrl/api/user/avatar'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    if (r.statusCode >= 400) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {}
      throw Exception(r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final r = await _execWithRefresh(() =>
        http.get(Uri.parse('$baseUrl/api/dashboard'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // API Keys (Integrações)
  Future<List<dynamic>> listarApiKeys() async {
    final r = await _execWithRefresh(
      () => http.get(Uri.parse('$baseUrl/api/api-keys'), headers: _headers()),
    );
    if (r.statusCode >= 400) {
      throw Exception(r.body);
    }
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarApiKey({
    required String provider,
    required String token,
    String? label,
  }) async {
    final payload = <String, dynamic>{
      'provider': provider,
      'token': token,
      if (label != null && label.isNotEmpty) 'label': label,
    };
    final r = await _execWithRefresh(
      () => http.post(
        Uri.parse('$baseUrl/api/api-keys'),
        headers: _headers(),
        body: jsonEncode(payload),
      ),
    );
    if (r.statusCode >= 400) {
      try {
        final body = jsonDecode(r.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {
        // fallback para corpo bruto
      }
      throw Exception(r.body);
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> vagas(
      {int page = 1, int limit = 50, String? status, String? q}) async {
    final qp = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null) qp['status'] = status;
    if (q != null) qp['q'] = q;
    final uri = Uri.parse('$baseUrl/api/vagas').replace(queryParameters: qp);
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<Map<String, dynamic>> criarVaga(Map<String, dynamic> vaga) async {
    final payload = {
      'title': vaga['titulo'],
      'description': vaga['descricao'],
      'requirements': vaga['requisitos'],
      'status':
          (vaga['status'] ?? 'aberta').toString().toLowerCase() == 'aberta'
              ? 'open'
              : 'closed',
      'seniority': vaga['nivel'],
      'location_type': vaga['regime'],
      if (vaga['local'] != null) 'unit': vaga['local'],
      if (vaga['salary_min'] != null) 'salary_min': vaga['salary_min'],
      if (vaga['salary_max'] != null) 'salary_max': vaga['salary_max'],
      if (vaga['skills_required'] != null)
        'skills_required': vaga['skills_required'],
    };
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/jobs'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarVaga(
      String id, Map<String, dynamic> vaga) async {
    final payload = {
      if (vaga.containsKey('titulo')) 'title': vaga['titulo'],
      if (vaga.containsKey('descricao')) 'description': vaga['descricao'],
      if (vaga.containsKey('requisitos')) 'requirements': vaga['requisitos'],
      if (vaga.containsKey('status'))
        'status': (vaga['status'] ?? '').toString().toLowerCase() == 'aberta'
            ? 'open'
            : vaga['status'],
      if (vaga.containsKey('nivel')) 'seniority': vaga['nivel'],
      if (vaga.containsKey('regime')) 'location_type': vaga['regime'],
      if (vaga.containsKey('local')) 'unit': vaga['local'],
      if (vaga.containsKey('salary_min')) 'salary_min': vaga['salary_min'],
      if (vaga.containsKey('salary_max')) 'salary_max': vaga['salary_max'],
      if (vaga.containsKey('skills_required'))
        'skills_required': vaga['skills_required'],
    };
    final r = await _execWithRefresh(() => http.put(
        Uri.parse('$baseUrl/api/jobs/$id'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body);
  }

  Future<void> deletarVaga(String id) async {
    final r = await _execWithRefresh(() =>
        http.delete(Uri.parse('$baseUrl/api/jobs/$id'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
  }

  /// Finaliza vaga com candidato aprovado
  Future<Map<String, dynamic>> finalizarVaga(String jobId, {
    String? candidateId,
    required String candidateName,
    required String candidateEmail,
    String? interviewId,
  }) async {
    final payload = {
      if (candidateId != null) 'candidate_id': candidateId,
      'candidate_name': candidateName,
      'candidate_email': candidateEmail,
      if (interviewId != null) 'interview_id': interviewId,
    };
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/jobs/$jobId/finalize'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Reprova candidato para uma vaga
  Future<Map<String, dynamic>> reprovarCandidato(String jobId, {
    String? candidateId,
    String? interviewId,
    String? reason,
  }) async {
    final payload = {
      if (candidateId != null) 'candidate_id': candidateId,
      if (interviewId != null) 'interview_id': interviewId,
      if (reason != null) 'reason': reason,
    };
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/jobs/$jobId/reject-candidate'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> candidatos(
      {int page = 1, int limit = 50, String? q, String? skill}) async {
    final qp = <String, String>{'page': '$page', 'limit': '$limit'};
    if (q != null) qp['q'] = q;
    if (skill != null) qp['skill'] = skill;
    final uri =
        Uri.parse('$baseUrl/api/candidates').replace(queryParameters: qp);
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<List<dynamic>> historico() async {
    final r = await _execWithRefresh(() =>
        http.get(Uri.parse('$baseUrl/api/historico'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<List<String>> skills() async {
    final r = await _execWithRefresh(
        () => http.get(Uri.parse('$baseUrl/api/skills'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    final data = _asList(decoded);
    return data.map((e) => (e['name'] as String)).toList();
  }

  Future<Map<String, dynamic>> obterPipeline(String jobId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/jobs/$jobId/pipeline'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> criarCandidatura({
    required String jobId,
    required String candidateId,
    String? stageId,
  }) async {
    final payload = {
      'job_id': jobId,
      'candidate_id': candidateId,
      if (stageId != null) 'stage_id': stageId,
    };
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/applications'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<List<dynamic>> listarCandidaturas(
      {String? jobId, String? candidateId}) async {
    final qs = <String, String>{};
    if (jobId != null) qs['job_id'] = jobId;
    if (candidateId != null) qs['candidate_id'] = candidateId;
    final uri = Uri.parse('$baseUrl/api/applications')
        .replace(queryParameters: qs.isEmpty ? null : qs);
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<void> moverCandidatura({
    required String applicationId,
    required String toStageId,
    String? note,
  }) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/applications/$applicationId/move'),
          headers: _headers(),
          body: jsonEncode(
              {'to_stage_id': toStageId, if (note != null) 'note': note}),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
  }

  Future<Map<String, dynamic>> historicoCandidatura(
      String applicationId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/applications/$applicationId/history'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<List<dynamic>> listarEntrevistas(
      {String? status,
      String? jobId,
      String? candidateId,
      DateTime? from,
      DateTime? to,
      int page = 1,
      int limit = 20}) async {
    final qp = <String, String>{'page': '$page', 'limit': '$limit'};
    if (status != null) qp['status'] = status;
    if (jobId != null) qp['job_id'] = jobId;
    if (candidateId != null) qp['candidate_id'] = candidateId;
    if (from != null) qp['from'] = from.toIso8601String();
    if (to != null) qp['to'] = to.toIso8601String();
    final uri = Uri.parse('$baseUrl/api/interviews')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<Map<String, dynamic>> agendarEntrevista({
    required String jobId,
    required String candidateId,
    required DateTime scheduledAt,
    DateTime? endsAt,
    String mode = 'online',
  }) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/interviews'),
          headers: _headers(),
          body: jsonEncode({
            'job_id': jobId,
            'candidate_id': candidateId,
            'scheduled_at': scheduledAt.toIso8601String(),
            if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
            'mode': mode,
          }),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  // Interview Questions & Answers
  Future<List<dynamic>> listarPerguntasEntrevista(String interviewId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/interviews/$interviewId/questions'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<List<dynamic>> gerarPerguntasAIParaEntrevista(String interviewId,
      {int qtd = 8, String kind = 'TECNICA'}) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/interviews/$interviewId/questions?qtd=$qtd'),
          headers: _headers(),
          body: jsonEncode({'generate_ai': true, 'kind': kind}),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<Map<String, dynamic>> criarPerguntaManual(String interviewId,
      {required String prompt,
      String origin = 'MANUAL',
      String kind = 'TECNICA'}) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/interviews/$interviewId/questions'),
          headers: _headers(),
          body: jsonEncode({'prompt': prompt, 'origin': origin, 'kind': kind}),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<List<dynamic>> listarRespostasEntrevista(String interviewId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/interviews/$interviewId/answers'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  Future<Map<String, dynamic>> responderPergunta(String interviewId,
      {required String questionId, required String texto}) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/interviews/$interviewId/answers'),
          headers: _headers(),
          body: jsonEncode({'question_id': questionId, 'raw_text': texto}),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> atualizarEntrevista(String id,
      {DateTime? scheduledAt,
      DateTime? endsAt,
      String? mode,
      String? status}) async {
    final payload = {
      if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
    };
    final r = await _execWithRefresh(() => http.put(
        Uri.parse('$baseUrl/api/interviews/$id'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  // Ingestion jobs
  Future<Map<String, dynamic>> getIngestionJob(String id) async {
    final r = await _execWithRefresh(() =>
        http.get(Uri.parse('$baseUrl/api/ingestion/$id'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  // Resume search by term
  Future<List<dynamic>> searchResumes(String q) async {
    final uri = Uri.parse('$baseUrl/api/resumes/search')
        .replace(queryParameters: {'q': q});
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarCandidato({
    required String nome,
    required String email,
    String? telefone,
    String? linkedin,
    String? githubUrl,
    List<String>? skills,
    String? status,
  }) async {
    final payload = {
      'full_name': nome,
      'email': email,
      if (telefone != null && telefone.isNotEmpty) 'phone': telefone,
      if (linkedin != null && linkedin.isNotEmpty) 'linkedin': linkedin,
      if (githubUrl != null && githubUrl.isNotEmpty) 'github_url': githubUrl,
      if (skills != null) 'skills': skills,
      if (status != null) 'status': status,
    };
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/candidates'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<void> atualizarCandidato(
    String id, {
    String? nome,
    String? email,
    String? telefone,
    String? linkedin,
    String? githubUrl,
    List<String>? skills,
    String? status,
  }) async {
    final payload = {
      if (nome != null) 'full_name': nome,
      if (email != null) 'email': email,
      if (telefone != null) 'phone': telefone,
      if (linkedin != null) 'linkedin': linkedin,
      if (githubUrl != null) 'github_url': githubUrl,
      if (skills != null) 'skills': skills,
      if (status != null) 'status': status,
    };
    final r = await _execWithRefresh(() => http.put(
        Uri.parse('$baseUrl/api/candidates/$id'),
        headers: _headers(),
        body: jsonEncode(payload)));
    if (r.statusCode >= 400) throw Exception(r.body);
  }

  Future<void> deletarCandidato(String id) async {
    final r = await _execWithRefresh(() => http
        .delete(Uri.parse('$baseUrl/api/candidates/$id'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
  }

  Future<Map<String, dynamic>> obterDadosGithub(String candidateId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/candidates/$candidateId/github'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> entrevista(String id) async {
    final r = await _execWithRefresh(() => http
        .get(Uri.parse('$baseUrl/api/interviews/$id'), headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<List<dynamic>> gerarPerguntas(String entrevistaId,
      {int qtd = 8}) async {
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/interviews/$entrevistaId/questions?qtd=$qtd'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  // Upload de currículo (multipart/form-data) usando bytes
  Future<Map<String, dynamic>> uploadCurriculoBytes({
    required Uint8List bytes,
    required String filename,
    Map<String, dynamic>? candidato,
    String? vagaId,
  }) async {
    Future<http.Response> _send() async {
      final uri = Uri.parse('$baseUrl/api/curriculos/upload');
      final req = http.MultipartRequest('POST', uri);
      if (_token != null) {
        req.headers['Authorization'] = 'Bearer $_token';
      }
      req.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
      if (candidato != null) {
        if (candidato['id'] != null) {
          req.fields['candidate_id'] = candidato['id'].toString();
        } else {
          if (candidato['full_name'] != null)
            req.fields['full_name'] = candidato['full_name'];
          if (candidato['email'] != null)
            req.fields['email'] = candidato['email'];
          if (candidato['phone'] != null)
            req.fields['phone'] = candidato['phone'];
          if (candidato['linkedin'] != null)
            req.fields['linkedin'] = candidato['linkedin'];
          if (candidato['github_url'] != null)
            req.fields['github_url'] = candidato['github_url'];
        }
      }
      if (vagaId != null) req.fields['job_id'] = vagaId;
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    var resp = await _send();

    // Tenta renovar o token em caso de 401 (sessão expirada)
    if (resp.statusCode == 401 && _refresh != null) {
      final ok = await _tryRefresh();
      if (ok) {
        resp = await _send();
      }
    }

    if (resp.statusCode >= 400) {
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {
        // fallback para corpo bruto
      }
      throw Exception(resp.body);
    }

    final decoded = jsonDecode(resp.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> registrarDecisaoCurriculo(
    String resumeId, {
    required String decision, // 'APROVADO', 'REPROVADO', 'ENTREVISTA_AGENDADA'
    String? jobId,
    DateTime? scheduledAt,
  }) async {
    final payload = {
      'decision': decision,
      if (jobId != null) 'job_id': jobId,
      if (scheduledAt != null)
        'schedule': {'dataHora': scheduledAt.toIso8601String()},
    };

    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/resumes/$resumeId/decision'),
          headers: _headers(),
          body: jsonEncode(payload),
        ));

    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  // Chat - listar mensagens
  Future<List<dynamic>> listarMensagens(String entrevistaId) async {
    final r = await _execWithRefresh(() => http.get(
        Uri.parse('$baseUrl/api/interviews/$entrevistaId/messages'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asList(decoded);
  }

  // Chat - enviar mensagem
  Future<Map<String, dynamic>> enviarMensagem(
      String entrevistaId, String mensagem) async {
    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/interviews/$entrevistaId/chat'),
          headers: _headers(),
          body: jsonEncode({'mensagem': mensagem}),
        ));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  // Relatório - gerar/atualizar
  Future<Map<String, dynamic>> gerarRelatorio(String entrevistaId) async {
    final r = await _execWithRefresh(() => http.post(
        Uri.parse('$baseUrl/api/interviews/$entrevistaId/report'),
        headers: _headers()));
    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  // API Keys - deletar
  Future<void> deletarApiKey(String id) async {
    final r = await _execWithRefresh(
      () => http.delete(Uri.parse('$baseUrl/api/api-keys/$id'),
          headers: _headers()),
    );
    if (r.statusCode >= 400) {
      final contentType = r.headers['content-type'] ?? '';
      if (contentType.contains('application/json')) {
        try {
          final body = jsonDecode(r.body);
          if (body is Map && body['erro'] is String) {
            throw Exception(body['erro']);
          }
        } catch (_) {
          // ignorado, cai no fallback genérico
        }
      }
      throw Exception('Erro ao deletar API Key (status ${r.statusCode})');
    }
  }

  // ========== RF10: CRUD Completo de Usuários ==========

  /// RF10.1 - Criar Usuário (ADMIN, SUPER_ADMIN)
  Future<Map<String, dynamic>> criarUsuario({
    required String fullName,
    required String email,
    required String role,
    String? password,
    String? phone,
    String? department,
    String? jobTitle,
    bool? isActive,
    bool? emailVerified,
    Map<String, dynamic>? company,
  }) async {
    final payload = {
      'full_name': fullName,
      'email': email,
      'role': role,
      if (password != null) 'password': password,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (jobTitle != null) 'job_title': jobTitle,
      if (isActive != null) 'is_active': isActive,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (company != null) 'company': company,
    };

    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/usuarios'),
          headers: _headers(),
          body: jsonEncode(payload),
        ));

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF10.2 - Enviar Convite (ADMIN, SUPER_ADMIN)
  Future<Map<String, dynamic>> enviarConvite({
    required String fullName,
    required String email,
    String role = 'USER',
    String? phone,
    String? department,
    String? jobTitle,
    int expiresInDays = 7,
  }) async {
    final payload = {
      'full_name': fullName,
      'email': email,
      'role': role,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (jobTitle != null) 'job_title': jobTitle,
      'expires_in_days': expiresInDays,
    };

    final r = await _execWithRefresh(() => http.post(
          Uri.parse('$baseUrl/api/usuarios/invite'),
          headers: _headers(),
          body: jsonEncode(payload),
        ));

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF10.3 - Aceitar Convite (Público - sem autenticação)
  Future<Map<String, dynamic>> aceitarConvite({
    required String token,
    required String password,
  }) async {
    final payload = {
      'token': token,
      'password': password,
    };

    final r = await http.post(
      Uri.parse('$baseUrl/api/usuarios/accept-invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF10.4 - Listar Usuários (USER, RECRUITER, ADMIN, SUPER_ADMIN)
  Future<Map<String, dynamic>> listarUsuarios({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? department,
    String? status,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      if (department != null && department.isNotEmpty) 'department': department,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final uri = Uri.parse('$baseUrl/api/usuarios').replace(queryParameters: qp);
    final r = await _execWithRefresh(() => http.get(uri, headers: _headers()));

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return {
      'data': _asList(decoded['data'] ?? decoded),
      'meta': decoded['meta'] ?? {},
    };
  }

  /// RF10.5 - Detalhes do Usuário (USER, RECRUITER, ADMIN, SUPER_ADMIN)
  Future<Map<String, dynamic>> obterUsuarioPorId(String id) async {
    final r = await _execWithRefresh(
      () =>
          http.get(Uri.parse('$baseUrl/api/usuarios/$id'), headers: _headers()),
    );

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF10.6 - Atualizar Usuário (ADMIN, SUPER_ADMIN)
  Future<Map<String, dynamic>> atualizarUsuario(
    String id, {
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? department,
    String? jobTitle,
    String? bio,
    bool? isActive,
    bool? emailVerified,
    Map<String, dynamic>? preferences,
    String? password,
    bool? forcePasswordReset,
  }) async {
    final payload = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (department != null) 'department': department,
      if (jobTitle != null) 'job_title': jobTitle,
      if (bio != null) 'bio': bio,
      if (isActive != null) 'is_active': isActive,
      if (emailVerified != null) 'email_verified': emailVerified,
      if (preferences != null) 'preferences': preferences,
      if (password != null) 'password': password,
      if (forcePasswordReset != null)
        'force_password_reset': forcePasswordReset,
    };

    final r = await _execWithRefresh(() => http.put(
          Uri.parse('$baseUrl/api/usuarios/$id'),
          headers: _headers(),
          body: jsonEncode(payload),
        ));

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }

    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF10.7 - Deletar Usuário / Soft Delete (ADMIN, SUPER_ADMIN)
  Future<void> deletarUsuario(String id) async {
    final r = await _execWithRefresh(
      () => http.delete(Uri.parse('$baseUrl/api/usuarios/$id'),
          headers: _headers()),
    );

    if (r.statusCode >= 400) {
      final body = jsonDecode(r.body);
      if (body is Map && body['error'] is Map) {
        final error = body['error'];
        throw Exception('${error['code']}: ${error['message']}');
      }
      throw Exception(r.body);
    }
  }

  /// RF7 - Buscar Relatório de Entrevista
  Future<Map<String, dynamic>> obterRelatorioEntrevista(
      String interviewId) async {
    final r = await _execWithRefresh(
      () => http.get(
        Uri.parse('$baseUrl/api/interviews/$interviewId/report'),
        headers: _headers(),
      ),
    );

    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF7 - Atualizar Relatório
  Future<Map<String, dynamic>> atualizarRelatorio(
      String reportId, Map<String, dynamic> dados) async {
    final r = await _execWithRefresh(
      () => http.put(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        headers: _headers(),
        body: jsonEncode(dados),
      ),
    );

    if (r.statusCode >= 400) throw Exception(r.body);
    final decoded = jsonDecode(r.body);
    return _asMap(decoded['data'] ?? decoded);
  }

  /// RF7 - Deletar Relatório
  Future<void> deletarRelatorio(String reportId) async {
    final r = await _execWithRefresh(
      () => http.delete(
        Uri.parse('$baseUrl/api/reports/$reportId'),
        headers: _headers(),
      ),
    );

    if (r.statusCode >= 400) throw Exception(r.body);
  }

  Future<void> trocarSenha(String senhaAtual, String novaSenha) async {
    final resp = await _execWithRefresh(
      () => http.post(
        Uri.parse('$baseUrl/api/auth/change-password'),
        headers: _headers(),
        body: jsonEncode({'senha_atual': senhaAtual, 'nova_senha': novaSenha}),
      ),
    );
    if (resp.statusCode >= 400) {
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['erro'] is String) {
          throw Exception(body['erro']);
        }
      } catch (_) {}
      throw Exception(resp.body);
    }
  }
}
