# 🎯 Bob - Entrega RF10 e RF1 (MVP)

**Data**: 2025-01-XX  
**Agente**: Bob (Backend Architect)  
**Solicitante**: Alex (Frontend Flutter)

---

## 📋 Resumo Executivo

### Descobertas

✅ **RF10 (CRUD de Usuários)**: Já estava 100% implementado no backend  
✅ **RF1 (/api/curriculos/upload)**: Já estava implementado via alias para `/api/resumes/upload`

### Trabalho Realizado

🔧 **Padronização de Respostas**: Todos os endpoints de `usuarios.js` agora retornam respostas no formato envelope padrão do MVP:
- Sucesso: `{data: {...}, meta?: {...}}`
- Erro: `{error: {code: string, message: string}}`

🔧 **Códigos de Erro Semânticos**: Adicionados códigos de erro estruturados para facilitar tratamento no frontend:
- `MISSING_FIELDS`, `INVALID_ROLE`, `INVALID_DOCUMENT`
- `EMAIL_EXISTS`, `USER_NOT_FOUND`
- `CREATE_USER_FAILED`, `UPDATE_USER_FAILED`, `DELETE_USER_FAILED`
- etc.

---

## 🔐 RF10 - CRUD Completo de Usuários

### Base URL
```
http://localhost:3000/api/usuarios
```

### Autenticação
Todos os endpoints (exceto `POST /accept-invite`) exigem:
- Header: `Authorization: Bearer <JWT_TOKEN>`
- JWT deve conter: `{ id, company_id, role }`

### Multi-tenancy
Todos os dados são filtrados automaticamente por `company_id` do usuário logado.

---

## 📡 Endpoints RF10

### 1️⃣ POST /api/usuarios - Criar Usuário

**Permissões**: `ADMIN`, `SUPER_ADMIN`

**Request Body**:
```json
{
  "full_name": "Maria Silva",
  "email": "maria.silva@example.com",
  "role": "USER",
  "phone": "11999999999",
  "department": "RH",
  "job_title": "Analista de Recursos Humanos",
  "password": "Senha123!",
  "is_active": true,
  "email_verified": false,
  "company": {
    "name": "Empresa XYZ",
    "document": "12345678000190",
    "type": "CNPJ"
  }
}
```

**Campos**:
- ✅ **full_name** (obrigatório): Nome completo
- ✅ **email** (obrigatório): Email único no sistema
- ✅ **role** (obrigatório): `USER` | `RECRUITER` | `ADMIN` | `SUPER_ADMIN`
- password (opcional): Se não fornecido, user deve aceitar convite
- phone, department, job_title (opcionais)
- is_active (default: `true`)
- email_verified (default: `false`)
- **company** (opcional): Se fornecido, cria nova empresa e associa usuário

**Response 201 - Sucesso**:
```json
{
  "data": {
    "id": "uuid-v4",
    "full_name": "Maria Silva",
    "email": "maria.silva@example.com",
    "role": "USER",
    "company_id": "uuid-v4",
    "phone": "11999999999",
    "department": "RH",
    "job_title": "Analista de Recursos Humanos",
    "is_active": true,
    "email_verified": false,
    "force_password_reset": false,
    "created_at": "2025-01-15T10:30:00.000Z",
    "updated_at": "2025-01-15T10:30:00.000Z"
  }
}
```

**Errors**:
```json
// 400 - Campos faltando
{
  "error": {
    "code": "MISSING_FIELDS",
    "message": "full_name and email are required"
  }
}

// 400 - Role inválido
{
  "error": {
    "code": "INVALID_ROLE",
    "message": "Invalid role"
  }
}

// 400 - Documento inválido (se company fornecido)
{
  "error": {
    "code": "INVALID_DOCUMENT",
    "message": "Invalid company type/document"
  }
}

// 409 - Email já existe
{
  "error": {
    "code": "EMAIL_EXISTS",
    "message": "User with this email already exists"
  }
}

// 500 - Erro interno
{
  "error": {
    "code": "CREATE_USER_FAILED",
    "message": "Failed to create user"
  }
}
```

---

### 2️⃣ POST /api/usuarios/invite - Enviar Convite

**Permissões**: `ADMIN`, `SUPER_ADMIN`

**Request Body**:
```json
{
  "full_name": "João Santos",
  "email": "joao.santos@example.com",
  "role": "RECRUITER",
  "phone": "11988888888",
  "department": "Recrutamento",
  "job_title": "Recrutador Sênior",
  "expires_in_days": 7
}
```

**Campos**:
- ✅ **full_name** (obrigatório)
- ✅ **email** (obrigatório)
- role (default: `USER`)
- phone, department, job_title (opcionais)
- expires_in_days (default: `7`)

**Response 201 - Sucesso**:
```json
{
  "data": {
    "user": {
      "id": "uuid-v4",
      "full_name": "João Santos",
      "email": "joao.santos@example.com",
      "role": "RECRUITER",
      "company_id": "uuid-v4",
      "is_active": false,
      "email_verified": false,
      "force_password_reset": true,
      "created_at": "2025-01-15T10:35:00.000Z"
    },
    "invite_token": "abc123def456...",
    "expires_at": "2025-01-22T10:35:00.000Z"
  }
}
```

**Errors**:
```json
// 400 - Campos faltando
{
  "error": {
    "code": "MISSING_FIELDS",
    "message": "full_name and email are required"
  }
}

// 400 - Role inválido
{
  "error": {
    "code": "INVALID_ROLE",
    "message": "Invalid role"
  }
}

// 409 - Email já existe
{
  "error": {
    "code": "EMAIL_EXISTS",
    "message": "User with this email already exists"
  }
}

// 500 - Erro ao criar convite
{
  "error": {
    "code": "INVITE_FAILED",
    "message": "Failed to create invitation"
  }
}
```

**⚠️ Importante**: O frontend deve enviar email com link contendo o `invite_token`:
```
https://app.talentmatchia.com/accept-invite?token={invite_token}
```

---

### 3️⃣ POST /api/usuarios/accept-invite - Aceitar Convite

**Permissões**: 🔓 Público (sem autenticação)

**Request Body**:
```json
{
  "token": "abc123def456...",
  "password": "SenhaSuperSegura123!"
}
```

**Campos**:
- ✅ **token** (obrigatório): Token recebido por email
- ✅ **password** (obrigatório): Nova senha do usuário

**Response 200 - Sucesso**:
```json
{
  "data": {
    "message": "Invitation accepted successfully",
    "user": {
      "id": "uuid-v4",
      "full_name": "João Santos",
      "email": "joao.santos@example.com",
      "role": "RECRUITER",
      "company_id": "uuid-v4",
      "is_active": true,
      "email_verified": true,
      "force_password_reset": false
    }
  }
}
```

**Errors**:
```json
// 400 - Token ou senha faltando
{
  "error": {
    "code": "MISSING_FIELDS",
    "message": "Token and password are required"
  }
}

// 400 - Token inválido ou expirado
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Invalid or expired invitation token"
  }
}

// 500 - Erro ao aceitar convite
{
  "error": {
    "code": "ACCEPT_INVITE_FAILED",
    "message": "Failed to accept invitation"
  }
}
```

---

### 4️⃣ GET /api/usuarios - Listar Usuários

**Permissões**: `USER`, `RECRUITER`, `ADMIN`, `SUPER_ADMIN`

**Query Parameters**:
```
?page=1&limit=20&search=maria&role=RECRUITER&department=RH&status=active
```

**Parâmetros**:
- page (default: `1`)
- limit (default: `20`)
- search (opcional): Busca por nome ou email
- role (opcional): Filtrar por role
- department (opcional): Filtrar por departamento
- status (opcional): `active` | `inactive`

**Response 200 - Sucesso**:
```json
{
  "data": [
    {
      "id": "uuid-v4",
      "full_name": "Maria Silva",
      "email": "maria.silva@example.com",
      "role": "RECRUITER",
      "department": "RH",
      "job_title": "Recrutadora",
      "phone": "11999999999",
      "is_active": true,
      "email_verified": true,
      "last_login_at": "2025-01-15T09:00:00.000Z",
      "created_at": "2025-01-10T10:00:00.000Z",
      "updated_at": "2025-01-15T09:00:00.000Z"
    },
    {
      "id": "uuid-v4-2",
      "full_name": "João Santos",
      "email": "joao.santos@example.com",
      "role": "USER",
      "department": "TI",
      "is_active": true,
      "email_verified": false,
      "created_at": "2025-01-12T14:30:00.000Z",
      "updated_at": "2025-01-12T14:30:00.000Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 42,
    "pages": 3
  }
}
```

**Errors**:
```json
// 500 - Erro ao buscar usuários
{
  "error": {
    "code": "LIST_USERS_FAILED",
    "message": "Failed to list users"
  }
}
```

---

### 5️⃣ GET /api/usuarios/:id - Detalhes do Usuário

**Permissões**: `USER`, `RECRUITER`, `ADMIN`, `SUPER_ADMIN`

**URL Parameters**:
- ✅ **id** (UUID): ID do usuário

**Response 200 - Sucesso**:
```json
{
  "data": {
    "id": "uuid-v4",
    "full_name": "Maria Silva",
    "email": "maria.silva@example.com",
    "role": "RECRUITER",
    "company_id": "uuid-v4",
    "phone": "11999999999",
    "department": "RH",
    "job_title": "Recrutadora Sênior",
    "bio": "Especialista em recrutamento tech com 5 anos de experiência",
    "is_active": true,
    "email_verified": true,
    "force_password_reset": false,
    "preferences": {
      "theme": "dark",
      "notifications": true
    },
    "created_by": "uuid-v4-admin",
    "last_login_at": "2025-01-15T09:00:00.000Z",
    "created_at": "2025-01-10T10:00:00.000Z",
    "updated_at": "2025-01-15T09:00:00.000Z",
    "company": {
      "id": "uuid-v4",
      "name": "Tech Recruiters LTDA",
      "document": "12345678000190",
      "type": "CNPJ"
    },
    "invited_by": {
      "id": "uuid-v4-admin",
      "full_name": "Admin Master",
      "email": "admin@techrecruiters.com"
    }
  }
}
```

**Errors**:
```json
// 404 - Usuário não encontrado
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User not found"
  }
}

// 500 - Erro ao buscar usuário
{
  "error": {
    "code": "GET_USER_FAILED",
    "message": "Failed to get user details"
  }
}
```

---

### 6️⃣ PUT /api/usuarios/:id - Atualizar Usuário

**Permissões**: `ADMIN`, `SUPER_ADMIN`

**URL Parameters**:
- ✅ **id** (UUID): ID do usuário

**Request Body** (todos os campos opcionais):
```json
{
  "full_name": "Maria Silva Santos",
  "email": "maria.santos@example.com",
  "role": "ADMIN",
  "phone": "11988887777",
  "department": "Gestão de Pessoas",
  "job_title": "Coordenadora de RH",
  "bio": "Coordenadora de RH com foco em tech",
  "is_active": true,
  "email_verified": true,
  "preferences": {
    "theme": "light",
    "notifications": false
  },
  "password": "NovaSenha123!",
  "force_password_reset": false
}
```

**Campos**:
- Todos são opcionais
- **role**: Deve ser um dos valores válidos (`USER`, `RECRUITER`, `ADMIN`, `SUPER_ADMIN`)
- **password**: Se fornecido, atualiza a senha e define `force_password_reset = false`
- **force_password_reset**: Se `true`, força usuário a trocar senha no próximo login

**Response 200 - Sucesso**:
```json
{
  "data": {
    "id": "uuid-v4",
    "full_name": "Maria Silva Santos",
    "email": "maria.santos@example.com",
    "role": "ADMIN",
    "company_id": "uuid-v4",
    "phone": "11988887777",
    "department": "Gestão de Pessoas",
    "job_title": "Coordenadora de RH",
    "bio": "Coordenadora de RH com foco em tech",
    "is_active": true,
    "email_verified": true,
    "force_password_reset": false,
    "preferences": {
      "theme": "light",
      "notifications": false
    },
    "last_login_at": "2025-01-15T09:00:00.000Z",
    "created_at": "2025-01-10T10:00:00.000Z",
    "updated_at": "2025-01-15T11:25:00.000Z"
  }
}
```

**Errors**:
```json
// 400 - Nenhum campo para atualizar
{
  "error": {
    "code": "NO_FIELDS",
    "message": "No fields to update"
  }
}

// 400 - Role inválido
{
  "error": {
    "code": "INVALID_ROLE",
    "message": "Invalid role"
  }
}

// 404 - Usuário não encontrado
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User not found"
  }
}

// 409 - Email já existe (se tentar mudar para email existente)
{
  "error": {
    "code": "EMAIL_EXISTS",
    "message": "Email already exists"
  }
}

// 500 - Erro ao atualizar
{
  "error": {
    "code": "UPDATE_USER_FAILED",
    "message": "Failed to update user"
  }
}
```

---

### 7️⃣ DELETE /api/usuarios/:id - Deletar Usuário (Soft Delete)

**Permissões**: `ADMIN`, `SUPER_ADMIN`

**URL Parameters**:
- ✅ **id** (UUID): ID do usuário

**Response 200 - Sucesso**:
```json
{
  "data": {
    "message": "User deleted successfully"
  }
}
```

**Errors**:
```json
// 400 - Tentativa de deletar a si mesmo
{
  "error": {
    "code": "CANNOT_DELETE_SELF",
    "message": "Cannot delete your own account"
  }
}

// 404 - Usuário não encontrado
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User not found"
  }
}

// 500 - Erro ao deletar
{
  "error": {
    "code": "DELETE_USER_FAILED",
    "message": "Failed to delete user"
  }
}
```

**⚠️ Importante**: 
- É um **soft delete**: Define `deleted_at = NOW()`
- Usuário não aparece mais em listagens (filtradas por `deleted_at IS NULL`)
- Dados permanecem no banco para auditoria

---

## 📄 RF1 - Upload de Currículo

### Base URL
```
http://localhost:3000/api/curriculos/upload
```
ou
```
http://localhost:3000/api/resumes/upload
```

**Nota**: `/api/curriculos` é um alias em português para `/api/resumes`.

---

## 📡 Endpoint RF1

### POST /api/curriculos/upload - Upload de Currículo

**Permissões**: `USER`, `RECRUITER`, `ADMIN`, `SUPER_ADMIN`

**Content-Type**: `multipart/form-data`

**Form Fields**:
```
file: <binary>                    # ✅ Obrigatório
candidate_id: uuid-v4             # Opcional: vincular a candidato existente
job_id: uuid-v4                   # Opcional: vincular a vaga

# OU criar novo candidato (se candidate_id não fornecido):
full_name: "Carlos Souza"         # ✅ Obrigatório se candidate_id não fornecido
email: "carlos@example.com"       # ✅ Obrigatório se candidate_id não fornecido
phone: "11977777777"              # Opcional
linkedin: "linkedin.com/in/carlos" # Opcional
github_url: "github.com/carlos"   # Opcional
```

**File Constraints**:
- Formato: PDF, TXT, DOCX
- Tamanho máximo: 5 MB
- Armazenamento: `/uploads/{company_id}/{uuid}.{ext}`

**Request Example (via Postman/Insomnia)**:
```
POST /api/curriculos/upload
Content-Type: multipart/form-data
Authorization: Bearer <JWT_TOKEN>

Form Data:
- file: curriculum_carlos.pdf
- full_name: "Carlos Souza"
- email: "carlos.souza@example.com"
- phone: "11977777777"
- linkedin: "linkedin.com/in/carlos-souza"
- github_url: "github.com/carlosouza"
- job_id: "uuid-da-vaga"
```

**Response 201 - Sucesso**:
```json
{
  "data": {
    "id": "uuid-v4",
    "candidate_id": "uuid-v4",
    "job_id": "uuid-da-vaga",
    "file_id": "uuid-v4-file",
    "original_filename": "curriculum_carlos.pdf",
    "file_size": 245678,
    "mime_type": "application/pdf",
    "status": "pending",
    "file_url": "/uploads/uuid-company/uuid-v4.pdf",
    "created_at": "2025-01-15T12:00:00.000Z",
    "updated_at": "2025-01-15T12:00:00.000Z"
  }
}
```

**Campos da Resposta**:
- **id**: UUID do registro de currículo
- **candidate_id**: UUID do candidato (criado ou existente)
- **job_id**: UUID da vaga (se fornecido)
- **file_id**: UUID do arquivo no sistema de storage
- **original_filename**: Nome original do arquivo
- **file_size**: Tamanho em bytes
- **mime_type**: Tipo MIME do arquivo
- **status**: `pending` | `reviewed` | `accepted` | `rejected`
- **file_url**: URL relativa para download/acesso ao arquivo
- **created_at**: Timestamp de criação
- **updated_at**: Timestamp de última atualização

**Errors**:
```json
// 400 - Arquivo não enviado
{
  "error": {
    "code": "FILE_REQUIRED",
    "message": "No file uploaded"
  }
}

// 400 - Campos obrigatórios faltando (ao criar candidato)
{
  "error": {
    "code": "MISSING_FIELDS",
    "message": "full_name and email are required to create candidate"
  }
}

// 400 - Candidato não encontrado ou não pertence à empresa
{
  "error": {
    "code": "INVALID_CANDIDATE",
    "message": "Candidate not found or does not belong to your company"
  }
}

// 400 - Vaga não encontrada ou não pertence à empresa
{
  "error": {
    "code": "INVALID_JOB",
    "message": "Job not found or does not belong to your company"
  }
}

// 409 - Email já existe (ao criar candidato)
{
  "error": {
    "code": "EMAIL_EXISTS",
    "message": "Candidate with this email already exists"
  }
}

// 500 - Erro ao fazer upload
{
  "error": {
    "code": "UPLOAD_FAILED",
    "message": "Failed to upload resume"
  }
}
```

---

## 🎨 Frontend - Como Consumir

### Exemplo Flutter (usuarios.dart)

```dart
class UsuariosService {
  final String baseUrl = 'http://localhost:3000/api/usuarios';
  final AuthService authService;

  UsuariosService(this.authService);

  // Listar usuários
  Future<Map<String, dynamic>> listarUsuarios({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? department,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null) 'search': search,
      if (role != null) 'role': role,
      if (department != null) 'department': department,
      if (status != null) 'status': status,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'users': json['data'],
        'meta': json['meta'],
      };
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Criar usuário
  Future<Map<String, dynamic>> criarUsuario(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Enviar convite
  Future<Map<String, dynamic>> enviarConvite(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invite'),
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Aceitar convite (público)
  Future<Map<String, dynamic>> aceitarConvite(String token, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accept-invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Detalhes do usuário
  Future<Map<String, dynamic>> buscarUsuario(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Atualizar usuário
  Future<Map<String, dynamic>> atualizarUsuario(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }

  // Deletar usuário
  Future<void> deletarUsuario(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer ${authService.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }
}
```

### Exemplo Flutter (curriculos_service.dart)

```dart
class CurriculosService {
  final String baseUrl = 'http://localhost:3000/api/curriculos/upload';
  final AuthService authService;

  CurriculosService(this.authService);

  Future<Map<String, dynamic>> uploadCurriculo({
    required File file,
    String? candidateId,
    String? jobId,
    String? fullName,
    String? email,
    String? phone,
    String? linkedin,
    String? githubUrl,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    
    // Headers
    request.headers['Authorization'] = 'Bearer ${authService.token}';
    
    // File
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    // Fields
    if (candidateId != null) {
      request.fields['candidate_id'] = candidateId;
    } else {
      if (fullName != null) request.fields['full_name'] = fullName;
      if (email != null) request.fields['email'] = email;
    }
    
    if (jobId != null) request.fields['job_id'] = jobId;
    if (phone != null) request.fields['phone'] = phone;
    if (linkedin != null) request.fields['linkedin'] = linkedin;
    if (githubUrl != null) request.fields['github_url'] = githubUrl;
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      final error = jsonDecode(response.body)['error'];
      throw Exception('${error['code']}: ${error['message']}');
    }
  }
}
```

---

## 🔍 Tratamento de Erros no Frontend

### Exemplo de tratamento genérico

```dart
Future<void> handleApiCall(Future<void> Function() apiCall) async {
  try {
    await apiCall();
    // Sucesso
    showSuccessSnackBar('Operação realizada com sucesso');
  } catch (e) {
    final errorMessage = e.toString();
    
    // Parsear código de erro
    if (errorMessage.contains('EMAIL_EXISTS')) {
      showErrorDialog('Este email já está cadastrado no sistema');
    } else if (errorMessage.contains('INVALID_ROLE')) {
      showErrorDialog('Perfil de usuário inválido');
    } else if (errorMessage.contains('USER_NOT_FOUND')) {
      showErrorDialog('Usuário não encontrado');
    } else if (errorMessage.contains('UNAUTHORIZED')) {
      // Redirecionar para login
      navigateToLogin();
    } else {
      // Erro genérico
      showErrorDialog('Ocorreu um erro. Tente novamente mais tarde.');
    }
  }
}
```

---

## 📊 Referência de Códigos de Erro

| Código | Significado | Ação Sugerida |
|--------|-------------|---------------|
| `MISSING_FIELDS` | Campos obrigatórios faltando | Validar formulário antes de enviar |
| `INVALID_ROLE` | Role inválido | Usar um dos valores: USER, RECRUITER, ADMIN, SUPER_ADMIN |
| `INVALID_DOCUMENT` | CPF/CNPJ inválido | Validar formato do documento |
| `EMAIL_EXISTS` | Email já cadastrado | Informar usuário que email já existe |
| `USER_NOT_FOUND` | Usuário não encontrado | Verificar se ID está correto ou atualizar lista |
| `INVALID_TOKEN` | Token de convite inválido/expirado | Solicitar novo convite |
| `CANNOT_DELETE_SELF` | Usuário tentou deletar a si mesmo | Impedir ação no frontend |
| `NO_FIELDS` | Nenhum campo fornecido para atualização | Validar que pelo menos 1 campo foi alterado |
| `FILE_REQUIRED` | Arquivo não enviado no upload | Validar que arquivo foi selecionado |
| `INVALID_CANDIDATE` | Candidato não encontrado/não pertence à empresa | Verificar candidate_id |
| `INVALID_JOB` | Vaga não encontrada/não pertence à empresa | Verificar job_id |
| `*_FAILED` | Erro interno do servidor | Mostrar mensagem genérica e reportar erro |

---

## ✅ Checklist de Integração para Alex

### RF10 - Usuários

- [ ] **Tela de Listagem de Usuários**
  - [ ] Consumir `GET /api/usuarios` com paginação
  - [ ] Implementar busca por nome/email
  - [ ] Implementar filtros (role, department, status)
  - [ ] Mostrar `meta.total` e `meta.pages`
  - [ ] Tratar erro `LIST_USERS_FAILED`

- [ ] **Tela de Criação de Usuário**
  - [ ] Formulário com validação de campos obrigatórios
  - [ ] Dropdown de roles (USER, RECRUITER, ADMIN, SUPER_ADMIN)
  - [ ] Campo opcional para criar empresa junto
  - [ ] Consumir `POST /api/usuarios`
  - [ ] Tratar erros: `MISSING_FIELDS`, `INVALID_ROLE`, `EMAIL_EXISTS`, `INVALID_DOCUMENT`

- [ ] **Tela de Convite de Usuário**
  - [ ] Formulário de convite
  - [ ] Consumir `POST /api/usuarios/invite`
  - [ ] Gerar link de convite com `invite_token`
  - [ ] Enviar email com link (integração com serviço de email)
  - [ ] Tratar erros: `MISSING_FIELDS`, `INVALID_ROLE`, `EMAIL_EXISTS`

- [ ] **Tela de Aceitar Convite** (pública)
  - [ ] Extrair `token` da URL
  - [ ] Formulário de definição de senha
  - [ ] Consumir `POST /api/usuarios/accept-invite`
  - [ ] Redirecionar para login após sucesso
  - [ ] Tratar erros: `INVALID_TOKEN`, `ACCEPT_INVITE_FAILED`

- [ ] **Tela de Detalhes do Usuário**
  - [ ] Consumir `GET /api/usuarios/:id`
  - [ ] Mostrar todos os dados (incluindo company, invited_by)
  - [ ] Botão "Editar" (redirecionar para tela de edição)
  - [ ] Tratar erros: `USER_NOT_FOUND`, `GET_USER_FAILED`

- [ ] **Tela de Edição de Usuário**
  - [ ] Carregar dados atuais via `GET /api/usuarios/:id`
  - [ ] Formulário preenchido com dados atuais
  - [ ] Todos os campos opcionais
  - [ ] Campo de senha (opcional)
  - [ ] Checkbox `force_password_reset`
  - [ ] Consumir `PUT /api/usuarios/:id`
  - [ ] Tratar erros: `NO_FIELDS`, `INVALID_ROLE`, `EMAIL_EXISTS`, `USER_NOT_FOUND`

- [ ] **Funcionalidade de Deletar Usuário**
  - [ ] Botão "Deletar" na listagem ou detalhes
  - [ ] Dialog de confirmação
  - [ ] Impedir deletar usuário logado
  - [ ] Consumir `DELETE /api/usuarios/:id`
  - [ ] Atualizar lista após sucesso
  - [ ] Tratar erros: `CANNOT_DELETE_SELF`, `USER_NOT_FOUND`

### RF1 - Upload de Currículo

- [ ] **Tela de Upload de Currículo**
  - [ ] File picker (PDF, TXT, DOCX)
  - [ ] Validação de tamanho máximo (5 MB)
  - [ ] Dropdown para selecionar vaga (opcional)
  - [ ] Dropdown para selecionar candidato existente (opcional)
  - [ ] OU formulário para criar novo candidato (full_name, email obrigatórios)
  - [ ] Consumir `POST /api/curriculos/upload`
  - [ ] Mostrar progresso de upload
  - [ ] Redirecionar para detalhes do currículo após sucesso
  - [ ] Tratar erros: `FILE_REQUIRED`, `MISSING_FIELDS`, `INVALID_CANDIDATE`, `INVALID_JOB`, `EMAIL_EXISTS`

- [ ] **Preview/Download de Arquivo**
  - [ ] Usar `file_url` da resposta para exibir/baixar arquivo
  - [ ] Exemplo: `http://localhost:3000${file_url}`

---

## 🚀 Próximos Passos (Sugestões)

1. **Testes de Integração**:
   - Testar todos os endpoints via Postman/Insomnia
   - Validar formato de resposta envelope
   - Testar todos os cenários de erro

2. **Documentação de Autenticação**:
   - Criar guia de login/registro para Alex
   - Documentar estrutura do JWT
   - Explicar refresh token (se implementado)

3. **Padronização de Outros Endpoints**:
   - Verificar `interviews.js`, `candidates.js`, `jobs.js`
   - Aplicar mesmo padrão de envelope
   - Adicionar códigos de erro semânticos

4. **Middleware de Validação**:
   - Criar middleware para validar schemas (Joi/Yup)
   - Centralizar validações de campos obrigatórios
   - Retornar erros detalhados por campo

5. **Logs e Monitoring**:
   - Implementar logging estruturado (Winston/Pino)
   - Adicionar tracing de requisições
   - Configurar alertas para erros 500

---

## 📝 Notas Finais

### Multi-tenancy
Todos os endpoints filtram automaticamente por `company_id` do usuário logado. Não é possível acessar dados de outras empresas.

### Auditoria
Todas as operações de CUD (Create, Update, Delete) são registradas na tabela `audit_logs` com:
- `user_id`: Quem executou a ação
- `action`: create, update, delete
- `resource_type`: users, resumes, etc.
- `resource_id`: ID do recurso afetado
- `changes`: JSON com alterações

### Soft Delete
Usuários deletados não são removidos do banco, apenas marcados com `deleted_at = NOW()`. Isso permite:
- Auditoria completa
- Recuperação de dados
- Integridade referencial

### Segurança
- Senhas: bcrypt com salt rounds = 10
- JWT: Expira em 24h (configurável)
- Tokens de convite: Expiram em 7 dias (configurável)
- CORS: Configurar para produção
- Rate limiting: Implementar para produção

---

**Documentação criada por**: Bob (Backend Architect)  
**Para**: Alex (Frontend Flutter Developer)  
**Status**: ✅ RF10 e RF1 100% operacionais e padronizados  
**Data**: 2025-01-15
